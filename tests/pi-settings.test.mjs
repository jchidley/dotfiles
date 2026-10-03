import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { resolve, join } from 'node:path';
import { spawnSync } from 'node:child_process';
import test from 'node:test';

const template = resolve(import.meta.dirname, '../private_dot_pi/agent/settings.json.tmpl');

for (const os of ['linux', 'windows']) {
  test(`current Pi settings render on ${os}, preserving only local identity`, (t) => {
    const home = mkdtempSync(join(tmpdir(), 'pi-settings-'));
    t.after(() => rmSync(home, { recursive: true, force: true }));
    function render() {
      const result = spawnSync('chezmoi', ['execute-template', '--file', template,
        '--override-data', JSON.stringify({ chezmoi: { os, homeDir: home } })],
        { encoding: 'utf8' });
      assert.equal(result.status, 0, result.stderr);
      return JSON.parse(result.stdout);
    }
    const fresh = render();
    assert.equal(fresh.defaultProvider, 'openai');
    assert.equal(fresh.defaultModel, 'gpt-6.1-sol');
    assert.equal(fresh.defaultThinkingLevel, 'medium');
    assert.equal(fresh.lastChangelogVersion, '1.0.1');
    assert.deepEqual(fresh.enabledModels, [
      'openai/gpt-6.1-sol', 'openai/gpt-6-astra', 'openai/gpt-6-luna',
    ]);
    assert.deepEqual(fresh.defaultTools, os === 'windows'
      ? ['read', 'powershell', 'edit', 'write', 'codemode'] : ['+codemode']);
    assert.equal(fresh.compaction.enabled, true);
    assert.equal(fresh.theme, 'system');
    assert.equal(fresh.terminal.showTerminalProgress, true);
    assert.equal(fresh.hideThinkingBlock, true);
    assert.equal(fresh.fullscreenCopyOnSelect, true);
    assert.equal('deviceId' in fresh, false);
    assert.deepEqual(fresh.packages.slice(1), [
      'npm:pi-typesafe', 'npm:pi-warden',
      'git:github.com/giuseppecrj/pi-herdr-agents@main', 'npm:pi-copy-message',
    ]);
    assert.equal(fresh.packages[0].source, '../../git/agent-skills');
    assert.ok(fresh.packages[0].skills.includes('!**/*'));
    mkdirSync(join(home, '.pi/agent'), { recursive: true });
    const deviceId = '00000000-0000-4000-8000-000000000001';
    writeFileSync(join(home, '.pi/agent/settings.json'), JSON.stringify({
      deviceId, defaultProvider: 'obsolete', extraRuntimeField: 'not-managed',
    }));
    assert.deepEqual(render(), { ...fresh, deviceId });
  });
}
