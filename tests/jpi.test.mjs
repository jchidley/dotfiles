import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { resolve, join } from 'node:path';
import { spawnSync } from 'node:child_process';
import test from 'node:test';

const launcher = resolve(import.meta.dirname, '../dot_local/bin/executable_jpi');

function fixture(t) {
  const root = mkdtempSync(join(tmpdir(), 'jpi-'));
  t.after(() => rmSync(root, { recursive: true, force: true }));
  const home = join(root, 'home #?% spaces');
  const checkout = join(home, 'git/pi-mono');
  mkdirSync(checkout, { recursive: true });
  // Deliberately non-executable: jpi must invoke the maintained launcher via Bash.
  writeFileSync(join(checkout, 'pi-test.sh'), `#!/usr/bin/env bash
set -euo pipefail
exec node -e 'console.log(JSON.stringify({
  args: process.argv.slice(1), cwd: process.cwd(),
  openai: process.env.OPENAI_API_KEY,
  unrelated: process.env.PI_TEST_UNRELATED
})); process.exit(Number(process.env.PI_TEST_EXIT || 0));' -- "$@"
`, { mode: 0o644 });
  const run = (args = [], env = {}) => spawnSync('bash', [launcher, ...args], {
    cwd: root, encoding: 'utf8',
    env: { ...process.env, HOME: home, OPENAI_API_KEY: 'fake-openai',
      PI_TEST_UNRELATED: 'keep', ...env },
  });
  return { root, run };
}

function output(result) {
  assert.equal(result.status, 0, result.stderr);
  return JSON.parse(result.stdout);
}

test('delegates literal arguments and preserves cwd and environment', (t) => {
  const { root, run } = fixture(t);
  for (const args of [[], ['--print', 'a b', '', '*', 'quote"', '--help']]) {
    assert.deepEqual(output(run(args)), {
      args, cwd: root, openai: 'fake-openai', unrelated: 'keep',
    });
  }
});

test('--no-env is forwarded untouched for pi-test.sh to handle', (t) => {
  const { run } = fixture(t);
  const args = ['--print', '--no-env', 'hello world', '--no-env'];
  assert.deepEqual(output(run(args)).args, args);
  assert.equal(output(run(args)).openai, 'fake-openai');
});

test('propagates the development launcher exit status', (t) => {
  const { run } = fixture(t);
  assert.equal(run([], { PI_TEST_EXIT: '23' }).status, 23);
});

test('missing launcher fails with an actionable error', (t) => {
  const { root, run } = fixture(t);
  const home = join(root, 'missing');
  const result = run([], { HOME: home });
  assert.equal(result.status, 1);
  assert.equal(result.stderr,
    `jpi: missing development launcher: ${home}/git/pi-mono/pi-test.sh; restore the Pi development checkout.\n`);
  assert.equal(result.stdout, '');
});
