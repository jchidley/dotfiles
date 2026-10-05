import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, readFileSync, writeFileSync, symlinkSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { resolve, join } from 'node:path';
import { spawnSync } from 'node:child_process';
import test from 'node:test';

for (const command of ['jpi', 'pi']) {
  test(`${command}min forwards fixed flags and literal arguments, cwd, environment and exit status`, (t) => {
    const root = mkdtempSync(join(tmpdir(), 'pi-min-'));
    t.after(() => rmSync(root, { recursive: true, force: true }));
    writeFileSync(join(root, command), `#!/usr/bin/env bash
exec node -e 'console.log(JSON.stringify({args: process.argv.slice(1), cwd: process.cwd(), marker: process.env.PI_TEST_MARKER})); process.exit(Number(process.env.PI_TEST_EXIT || 0));' -- "$@"
`, { mode: 0o755 });
    // Materialize the chezmoi-managed executable and relative symlink in a path with spaces.
    const bin = join(root, 'installed bin');
    mkdirSync(bin);
    const source = resolve(import.meta.dirname, '../dot_local/bin');
    writeFileSync(join(bin, 'pimin'), readFileSync(join(source, 'executable_pimin')), { mode: 0o755 });
    const target = readFileSync(join(source, 'symlink_jpimin'), 'utf8').trim();
    assert.equal(target, 'pimin');
    symlinkSync(target, join(bin, 'jpimin'));
    const launcher = join(bin, `${command}min`);
    const home = join(root, 'home');
    const run = (args = [], exit = '0', env = {}) => spawnSync(launcher, args, {
      cwd: root, encoding: 'utf8',
      env: { ...process.env, HOME: home, PI_CODING_AGENT_DIR: '', PATH: `${root}:${process.env.PATH}`, PI_TEST_MARKER: 'keep', PI_TEST_EXIT: exit, ...env },
    });
    const fixed = ['-ne', '-ns', '-np', '-nc', '--no-themes', '--no-approve', '--tools', 'read,bash,edit,write'];
    for (const args of [[], ['--print', 'a b', '', '*', 'quote"']]) {
      const result = run(args);
      assert.equal(result.status, 0, result.stderr);
      assert.deepEqual(JSON.parse(result.stdout), { args: [...fixed, ...args], cwd: root, marker: 'keep' });
    }
    assert.equal(run([], '23').status, 23);

    // --discover must fail when ask-extra is missing.
    const missing = run(['--discover']);
    assert.equal(missing.status, 1);
    assert.equal(missing.stdout, '');
    assert.match(missing.stderr, /--discover requires .*ask-extra\/SKILL\.md/);

    for (const agentDir of [join(home, '.pi/agent'), join(root, 'custom agent #?% spaces')]) {
      const skill = join(agentDir, 'skills/ask-extra/SKILL.md');
      mkdirSync(join(agentDir, 'skills/ask-extra'), { recursive: true });
      writeFileSync(skill, ''); // The launcher checks existence, not skill contents.
      const env = agentDir === join(home, '.pi/agent') ? {} : { PI_CODING_AGENT_DIR: agentDir };
      const result = run(['--discover', '--print', 'hello'], '0', env);
      assert.equal(result.status, 0, result.stderr);
      assert.deepEqual(JSON.parse(result.stdout), {
        args: [...fixed, '--skill', skill, '--print', 'hello'], cwd: root, marker: 'keep',
      });
    }
  });
}
