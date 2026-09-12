import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import test from 'node:test';

const repositoryRoot = path.resolve(import.meta.dirname, '..');
const launcher = path.join(repositoryRoot, 'dot_local/bin/executable_pi-session-history');
const canonicalRelative = path.join('git', 'agent-skills', 'skills', 'pi-session-history', 'scripts', 'psh.mjs');
const powershellLaunchers = [
  path.join(repositoryRoot, 'dot_local/bin/pi-session-history.ps1'),
  path.join(repositoryRoot, 'dot_local/bin/psh.ps1'),
];

function renderIgnoreForOs(source, operatingSystem) {
  const included = [true];
  const output = [];
  for (const line of source.split('\n')) {
    const condition = line.match(/^\{\{ if (eq|ne) \.chezmoi\.os "([^"]+)" \}\}$/);
    if (condition) {
      const matches = operatingSystem === condition[2];
      included.push(included.at(-1) && (condition[1] === 'eq' ? matches : !matches));
    } else if (line === '{{ end }}') {
      assert.ok(included.length > 1, 'unexpected template end');
      included.pop();
    } else if (included.at(-1)) {
      output.push(line);
    }
  }
  assert.equal(included.length, 1, 'unterminated template condition');
  return output;
}

function writeCommand(bin, name, body) {
  const file = path.join(bin, name);
  fs.writeFileSync(file, `#!/bin/bash\nset -euo pipefail\n${body}`);
  fs.chmodSync(file, 0o755);
  return file;
}

function fixture({ withNode = true, withScript = true } = {}) {
  const home = fs.mkdtempSync(path.join(os.tmpdir(), 'pi-session-history-wrapper-'));
  const bin = path.join(home, 'bin');
  const capture = path.join(home, 'node-args');
  const canonical = path.join(home, canonicalRelative);
  fs.mkdirSync(bin);
  if (withScript) {
    fs.mkdirSync(path.dirname(canonical), { recursive: true });
    fs.writeFileSync(canonical, '// test placeholder\n');
  }
  if (withNode) {
    writeCommand(bin, 'node', 'printf \'%s\\0\' "$@" > "$NODE_CAPTURE"\nprintf \'delegated\\n\'\n');
  }
  return { home, bin, capture, canonical };
}

function run(context, args, environment = {}) {
  const env = {
    ...process.env,
    HOME: context.home,
    PATH: context.bin,
    HERDR_ENV: '',
    NODE_CAPTURE: context.capture,
    ...environment,
  };
  if (!Object.hasOwn(environment, 'PI_SESSION_FILE')) delete env.PI_SESSION_FILE;
  return spawnSync('/bin/bash', [launcher, ...args], { encoding: 'utf8', env });
}

function capturedArgs(context) {
  const args = fs.readFileSync(context.capture, 'utf8').split('\0');
  assert.equal(args.pop(), '');
  return args;
}

function clean(context) {
  fs.rmSync(context.home, { recursive: true, force: true });
}

test('passes explicit-session arguments unchanged to the canonical Node CLI', () => {
  const context = fixture();
  try {
    const args = ['conversation', '--last', '3', '--session', 'session with spaces.jsonl'];
    const result = run(context, args, { HERDR_ENV: '1' });

    assert.equal(result.status, 0, result.stderr);
    assert.deepEqual(capturedArgs(context), [context.canonical, ...args]);
  } finally {
    clean(context);
  }
});

test('delegates help without requiring Herdr or a session', () => {
  const context = fixture();
  try {
    const result = run(context, ['--help'], { HERDR_ENV: '1' });

    assert.equal(result.status, 0, result.stderr);
    assert.deepEqual(capturedArgs(context), [context.canonical, '--help']);
  } finally {
    clean(context);
  }
});

test('PI_SESSION_FILE suppresses Herdr discovery and is left for Node to consume', () => {
  const context = fixture();
  try {
    const args = ['assistants', '--last', '2'];
    const result = run(context, args, {
      HERDR_ENV: '1',
      PI_SESSION_FILE: '/tmp/session selected by environment.jsonl',
    });

    assert.equal(result.status, 0, result.stderr);
    assert.deepEqual(capturedArgs(context), [context.canonical, ...args]);
  } finally {
    clean(context);
  }
});

test('appends the current Herdr pane session when no session was supplied', () => {
  const context = fixture();
  const herdrArgs = path.join(context.home, 'herdr-args');
  const jqArgs = path.join(context.home, 'jq-args');
  const session = '/tmp/current pane session.jsonl';
  try {
    writeCommand(
      context.bin,
      'herdr',
      'printf \'%s\\0\' "$@" > "$HERDR_ARGS_CAPTURE"\nprintf \'{"result":{"pane":{"agent_session":{"value":"ignored-by-test-jq"}}}}\\n\'\n',
    );
    writeCommand(
      context.bin,
      'jq',
      'printf \'%s\\0\' "$@" > "$JQ_ARGS_CAPTURE"\nwhile IFS= read -r _; do :; done\nprintf \'%s\\n\' "$HERDR_SESSION"\n',
    );

    const args = ['users', '--last', '1'];
    const result = run(context, args, {
      HERDR_ENV: '1',
      HERDR_ARGS_CAPTURE: herdrArgs,
      JQ_ARGS_CAPTURE: jqArgs,
      HERDR_SESSION: session,
    });

    assert.equal(result.status, 0, result.stderr);
    assert.deepEqual(capturedArgs(context), [context.canonical, ...args, '--session', session]);
    assert.deepEqual(fs.readFileSync(herdrArgs, 'utf8').split('\0').slice(0, -1), ['pane', 'current', '--current']);
    assert.deepEqual(fs.readFileSync(jqArgs, 'utf8').split('\0').slice(0, -1), [
      '-er',
      '.result.pane.agent_session.value | select(endswith(".jsonl"))',
    ]);
  } finally {
    clean(context);
  }
});

test('outside Herdr delegates without inventing a session', () => {
  const context = fixture();
  try {
    const result = run(context, ['conversation']);

    assert.equal(result.status, 0, result.stderr);
    assert.deepEqual(capturedArgs(context), [context.canonical, 'conversation']);
  } finally {
    clean(context);
  }
});

test('fails clearly when node or the canonical script is missing', async (t) => {
  await t.test('missing node', () => {
    const context = fixture({ withNode: false });
    try {
      const result = run(context, ['--help']);
      assert.equal(result.status, 1);
      assert.match(result.stderr, /node is required but was not found in PATH/);
    } finally {
      clean(context);
    }
  });

  await t.test('missing canonical script', () => {
    const context = fixture({ withScript: false });
    try {
      const result = run(context, ['--help']);
      assert.equal(result.status, 1);
      assert.match(result.stderr, /canonical psh script not found:/);
      assert.match(result.stderr, /agent-skills\/skills\/pi-session-history\/scripts\/psh\.mjs/);
    } finally {
      clean(context);
    }
  });
});

test('chezmoi ignore conditions select only the platform-appropriate launchers', () => {
  const source = fs.readFileSync(path.join(repositoryRoot, '.chezmoiignore'), 'utf8');
  const linux = renderIgnoreForOs(source, 'linux');
  const windows = renderIgnoreForOs(source, 'windows');
  const targets = [
    '.local/bin/pi-session-history',
    '.local/bin/psh',
    '.local/bin/pi-session-history.ps1',
    '.local/bin/psh.ps1',
  ];

  assert.deepEqual(linux.filter((line) => targets.includes(line)), targets.slice(2));
  assert.deepEqual(windows.filter((line) => targets.includes(line)), targets.slice(0, 2));
});

test('PowerShell launchers enforce and preserve the canonical delegation contract', () => {
  for (const launcherPath of powershellLaunchers) {
    const source = fs.readFileSync(launcherPath, 'utf8');
    assert.match(source, /^#requires -Version 7\.0\r?$/m, launcherPath);
    assert.match(source, /Get-Command -Name node -CommandType Application\b/, launcherPath);
    assert.match(source, /Join-Path \$HOME 'git\/agent-skills\/skills\/pi-session-history\/scripts\/psh\.mjs'/, launcherPath);
    assert.match(source, /^& \$nodePath \$canonicalScript @args\r?$/m, launcherPath);
    assert.match(source, /^exit \$LASTEXITCODE\r?$/m, launcherPath);
  }
});

test('fails clearly when a Herdr discovery command is missing', async (t) => {
  await t.test('missing herdr', () => {
    const context = fixture();
    try {
      const result = run(context, ['conversation'], { HERDR_ENV: '1' });
      assert.equal(result.status, 1);
      assert.match(result.stderr, /herdr is required for current-pane session discovery/);
    } finally {
      clean(context);
    }
  });

  await t.test('missing jq', () => {
    const context = fixture();
    try {
      writeCommand(context.bin, 'herdr', 'printf \'{}\\n\'\n');
      const result = run(context, ['conversation'], { HERDR_ENV: '1' });
      assert.equal(result.status, 1);
      assert.match(result.stderr, /jq is required for current-pane session discovery/);
    } finally {
      clean(context);
    }
  });
});
