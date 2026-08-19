import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import test from 'node:test';

const script = path.resolve(import.meta.dirname, '../bin/executable_pi-session-move');

function fixture() {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'pi-session-move-'));
  const repo = path.join(root, 'repo');
  const sessions = path.join(root, 'sessions', '--wrong-cwd--');
  fs.mkdirSync(repo, { recursive: true });
  fs.mkdirSync(sessions, { recursive: true });
  assert.equal(spawnSync('git', ['init', '-q', repo]).status, 0);
  return { root, repo, sessions };
}

function writeSession(directory, id, timestamp = '2026-08-19T16:53:26.743Z') {
  const file = path.join(directory, `${timestamp.replaceAll(':', '-')}_${id}.jsonl`);
  fs.writeFileSync(file, `${JSON.stringify({ type: 'session', version: 3, id, timestamp, cwd: 'C:/wrong' })}\n${JSON.stringify({ type: 'message', id: 'abcd1234', parentId: null, timestamp, message: { role: 'user', content: 'hello' } })}\n`);
  return file;
}

function run(args, env = {}) {
  return spawnSync(process.execPath, [script, ...args], {
    encoding: 'utf8',
    env: { ...process.env, ...env },
  });
}

test('moves a session selected by ID into the current repository', () => {
  const { root, repo, sessions } = fixture();
  try {
    const id = '01a01af1-2657-72db-8e7f-422943ba4503';
    const source = writeSession(sessions, id);
    const result = run([id, '--repo', repo, '--sessions-dir', path.dirname(sessions)]);
    assert.equal(result.status, 0, result.stderr);
    const destination = path.join(repo, 'session-history', path.basename(source));
    assert.equal(fs.existsSync(source), false);
    assert.equal(fs.existsSync(destination), true);
    assert.equal(result.stdout.trim(), destination);
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
});

test('--latest explicitly selects the newest session', () => {
  const { root, repo, sessions } = fixture();
  try {
    const older = writeSession(sessions, '11111111-1111-1111-1111-111111111111', '2026-08-18T16:53:26.743Z');
    const newer = writeSession(sessions, '22222222-2222-2222-2222-222222222222', '2026-08-19T16:53:26.743Z');
    fs.utimesSync(older, new Date('2026-08-18'), new Date('2026-08-18'));
    fs.utimesSync(newer, new Date('2026-08-19'), new Date('2026-08-19'));
    const result = run(['--latest', '--repo', repo, '--sessions-dir', path.dirname(sessions)]);
    assert.equal(result.status, 0, result.stderr);
    assert.equal(fs.existsSync(older), true);
    assert.equal(fs.existsSync(newer), false);
    assert.equal(fs.existsSync(path.join(repo, 'session-history', path.basename(newer))), true);
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
});

test('refuses to move the active session', () => {
  const { root, repo, sessions } = fixture();
  try {
    const source = writeSession(sessions, '33333333-3333-3333-3333-333333333333');
    const result = run([source, '--repo', repo], { PI_SESSION_FILE: source });
    assert.notEqual(result.status, 0);
    assert.match(result.stderr, /Refusing to move the active Pi session/);
    assert.equal(fs.existsSync(source), true);
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
});

test('--dry-run validates but does not create or move files', () => {
  const { root, repo, sessions } = fixture();
  try {
    const source = writeSession(sessions, '44444444-4444-4444-4444-444444444444');
    const result = run([source, '--repo', repo, '--dry-run']);
    assert.equal(result.status, 0, result.stderr);
    assert.match(result.stdout, /Would move/);
    assert.equal(fs.existsSync(source), true);
    assert.equal(fs.existsSync(path.join(repo, 'session-history')), false);
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
});
