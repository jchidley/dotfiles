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
  // Exercise file-URL escaping as well as shell quoting.
  const home = join(root, 'home #?% spaces');
  const source = join(home, 'git/pi-mono/packages/coding-agent/src/experimental');
  mkdirSync(source, { recursive: true });
  writeFileSync(join(source, 'source-resolver.ts'), 'export {};\n');
  writeFileSync(join(source, 'cli.ts'), `
console.log(JSON.stringify({
  args: process.argv.slice(2), cwd: process.cwd(),
  openai: process.env.OPENAI_API_KEY,
  aws: process.env.AWS_PROFILE,
  github: process.env.GITHUB_TOKEN,
  unrelated: process.env.PI_TEST_UNRELATED
}));
process.exit(Number(process.env.PI_TEST_EXIT || 0));
`);
  const run = (args = [], env = {}) => spawnSync('bash', [launcher, ...args], {
    cwd: root, encoding: 'utf8',
    env: { ...process.env, HOME: home, OPENAI_API_KEY: 'fake-openai',
      AWS_PROFILE: 'fake-aws', GITHUB_TOKEN: 'fake-github',
      PI_TEST_UNRELATED: 'keep', ...env },
  });
  return { root, run };
}

function output(result) {
  assert.equal(result.status, 0, result.stderr);
  return JSON.parse(result.stdout.trim().split('\n').at(-1));
}

test('forwards literal arguments, preserves cwd and environment', (t) => {
  const { root, run } = fixture(t);
  const args = ['--print', 'a b', '', '*', 'quote"', '--help'];
  assert.deepEqual(output(run(args)), {
    args, cwd: root, openai: 'fake-openai', aws: 'fake-aws',
    github: 'fake-github', unrelated: 'keep',
  });
  assert.deepEqual(output(run()).args, []);
});

test('--no-env strips credentials and only consumes its own flag', (t) => {
  const { root, run } = fixture(t);
  const result = run(['--print', '--no-env', 'hello world', '--no-env']);
  assert.match(result.stdout, /^Running without API keys\.\.\.\n/);
  assert.deepEqual(output(result), {
    args: ['--print', 'hello world'], cwd: root, unrelated: 'keep',
  });
});

test('propagates the CLI exit status', (t) => {
  const { run } = fixture(t);
  assert.equal(run([], { PI_TEST_EXIT: '23' }).status, 23);
});

test('missing checkout fails with an actionable error before Node runs', (t) => {
  const { root, run } = fixture(t);
  const result = run([], { HOME: join(root, 'missing') });
  assert.equal(result.status, 1);
  assert.match(result.stderr, /jpi: missing source-resolver\.ts.*restore the Pi development checkout/);
  assert.equal(result.stdout, '');
});
