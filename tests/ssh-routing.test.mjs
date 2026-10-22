import assert from 'node:assert/strict';
import { EventEmitter } from 'node:events';
import { readFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { test } from 'node:test';
import vm from 'node:vm';

const source = readFileSync(new URL('../private_dot_ssh/private_wykh32j-route.cjs', import.meta.url), 'utf8');
function transport(port = '22') {
  const sockets = [], errors = [], stdin = new EventEmitter(), stdout = new EventEmitter();
  const process = { argv: ['node', 'route.cjs', port], stdin, stdout, exit: code => { throw new Error(`exit ${code}`); } };
  stdin.pipe = socket => { stdin.destination = socket; };
  stdin.unpipe = socket => { assert.equal(stdin.destination, socket); stdin.destination = undefined; };
  stdin.pause = () => { stdin.paused = true; };
  vm.runInNewContext(source, {
    process, console: { error: message => errors.push(message) },
    require: name => {
      assert.equal(name, 'node:net');
      return { createConnection: options => {
        const socket = new EventEmitter();
        socket.options = options;
        socket.setTimeout = value => { socket.timeout = value; };
        socket.destroy = error => { socket.emit('error', error); socket.emit('close'); };
        socket.pipe = target => { socket.destination = target; };
        sockets.push(socket);
        return socket;
      } };
    },
  });
  return { sockets, errors, process };
}

test('first route forwards streams and disables connect timeout', () => {
  const { sockets, process } = transport('2222');
  assert.equal(sockets.length, 1);
  const socket = sockets[0];
  assert.equal(socket.options.host, '10.0.1.124');
  assert.equal(socket.options.port, 2222);
  assert.equal(socket.timeout, 3000);
  socket.emit('connect');
  assert.equal(socket.timeout, 0);
  assert.equal(process.stdin.destination, socket);
  assert.equal(socket.destination, process.stdout);
  socket.emit('close');
  assert.equal(process.stdin.destination, undefined);
  assert.equal(process.stdin.paused, true);
});

for (const failure of ['error', 'timeout']) test(`${failure} falls back to .104`, () => {
  const { sockets, process } = transport();
  sockets[0].emit(failure, new Error('unreachable'));
  assert.equal(sockets.length, 2);
  assert.equal(sockets[1].options.host, '10.0.1.104');
  sockets[1].emit('connect');
  assert.equal(process.stdin.destination, sockets[1]);
});

test('both routes unavailable fail with an actionable error', () => {
  const { sockets, errors, process } = transport();
  sockets[0].emit('error', new Error('unreachable'));
  sockets[1].emit('timeout');
  assert.equal(sockets.length, 2);
  assert.equal(process.exitCode, 1);
  assert.match(errors[0], /neither 10\.0\.1\.124 nor 10\.0\.1\.104/);
});

test('an established connection failure never retries another host', () => {
  const { sockets, errors, process } = transport();
  sockets[0].emit('connect');
  sockets[0].emit('error', new Error('reset'));
  assert.equal(sockets.length, 1);
  assert.equal(process.exitCode, 1);
  assert.match(errors[0], /reset/);
});

for (const port of ['0', '-1', '65536', 'abc', '22.5']) test(`rejects invalid port ${port}`, () => {
  assert.throws(() => transport(port), /exit 1/);
});

function config(host) {
  const result = spawnSync('ssh', ['-G', '-F', new URL('../private_dot_ssh/private_config', import.meta.url).pathname, host], { encoding: 'utf8' });
  assert.equal(result.status, 0, result.stderr);
  return Object.fromEntries(result.stdout.trim().split('\n').map(line => {
    const split = line.indexOf(' ');
    return [line.slice(0, split), line.slice(split + 1)];
  }));
}
for (const host of ['wykh32j-deb', 'wykh32j-wifi', 'wykh32j', 'wykh32j-deb.chidley.home', 'wykh32j-wifi.chidley.home', 'wykh32j.chidley.home']) test(`${host} uses routing with strict Debian trust`, () => {
  const settings = config(host);
  assert.equal(settings.hostname, 'wykh32j-deb');
  assert.equal(settings.user, 'jack');
  assert.equal(settings.proxycommand, 'node ~/.ssh/wykh32j-route.cjs %p');
  assert.equal(settings.hostkeyalias, 'wykh32j-deb.chidley.home');
  assert.equal(settings.stricthostkeychecking, 'true');
  assert.match(settings.userknownhostsfile, /\/\.ssh\/nuc-known_hosts$/);
  assert.equal(settings.checkhostip, 'no');
  assert.equal(settings.updatehostkeys, 'false');
  assert.equal(settings.verifyhostkeydns, 'false');
  assert.equal(settings.identitiesonly, 'yes');
});

test('legacy alias has no custom route', () => {
  const settings = config('debian-nuc');
  assert.equal(settings.hostname, 'debian-nuc');
  assert.equal(settings.proxycommand, undefined);
  assert.equal(settings.hostkeyalias, undefined);
});
