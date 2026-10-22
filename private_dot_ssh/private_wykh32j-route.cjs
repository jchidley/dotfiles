// SSH transport only: SSH itself verifies the existing Debian host key.
// The first reachable SSH port wins; a different host key fails closed.
const net = require('node:net');
const routes = ['10.0.1.124', '10.0.1.104'];
const port = Number(process.argv[2] || 22);
if (!Number.isInteger(port) || port < 1 || port > 65535) {
  console.error('Invalid SSH port');
  process.exit(1);
}
function connect(index) {
  if (index === routes.length) {
    console.error('wykh32j: neither 10.0.1.124 nor 10.0.1.104 has a reachable SSH port');
    process.exitCode = 1;
    return;
  }
  const socket = net.createConnection({ host: routes[index], port });
  let connected = false;
  socket.setTimeout(3000);
  socket.once('timeout', () => {
    if (!connected) socket.destroy(new Error('connection timeout'));
  });
  socket.once('connect', () => {
    connected = true;
    socket.setTimeout(0);
    process.stdin.pipe(socket);
    socket.pipe(process.stdout);
  });
  socket.on('error', error => {
    if (!connected) connect(index + 1);
    else {
      console.error('wykh32j SSH transport: ' + error.message);
      process.exitCode = 1;
    }
  });
  socket.once('close', () => {
    if (connected) {
      process.stdin.unpipe(socket);
      process.stdin.pause();
    }
  });
}
process.stdout.on('error', () => process.exit(1));
connect(0);
