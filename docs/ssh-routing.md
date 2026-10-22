# Debian NUC SSH routing and Herdr

## Managed configuration

`private_dot_ssh/private_config` manages `~/.ssh/config`.
`private_dot_ssh/private_wykh32j-route.cjs` manages
`~/.ssh/wykh32j-route.cjs` with private permissions.

The Debian machine's canonical SSH name is `wykh32j-deb`. Its interface names
`wykh32j-wifi` and `wykh32j`, including their `.chidley.home` forms, use the
same transport. The obsolete `debian-nuc` alias is not configured.

The Node transport tries TCP port 22 at `10.0.1.124`, then `10.0.1.104` if the
first connection fails or takes more than three seconds. It bypasses DNS.
The first reachable port wins: SSH, not the transport, authenticates the host.
A wrong host key fails closed; it does not trigger a retry of another address.
This matters because the same physical machine can boot another OS.

Prerequisites remain machine-local and are not copied into this repository:

- Node on `PATH` and the private identity `~/.ssh/id_ed25519`.
- The independently verified Debian host key under
  `wykh32j-deb.chidley.home` in `~/.ssh/nuc-known_hosts`.
- Optional additional OS-specific aliases in `~/.ssh/nuc-names.conf`, included
  after the canonical routing block. OpenSSH ignores a missing include file.

Do not disable host-key checking or automatically trust a newly observed key to
make a route work. Provision verified host trust separately on a new machine.

Apply only these managed files:

```bash
chezmoi diff ~/.ssh/config ~/.ssh/wykh32j-route.cjs
chezmoi apply ~/.ssh/config ~/.ssh/wykh32j-route.cjs
```

## Herdr machine-local state

The saved machine has label **and SSH target** `wykh32j-deb`, session `default`,
and remains enabled. Its existing ID is `b5c5f769131f7ff7c9adbf8c458221d0`.
The target was updated in both:

- `~/.local/state/herdr/client/endpoints.json`
- `~/.local/state/herdr/client/ssh-metadata/b5c5f769131f7ff7c9adbf8c458221d0.json`

These runtime records are intentionally not managed by chezmoi: synchronizing
whole files could overwrite another machine's saved endpoints. Herdr's rename
command changes only the label, not the SSH target. Avoid using `machine add`
just to rename a target: it prepares the remote server and has remote effects.
No remote Herdr server start, restart, or installation was needed for this change.

## Verification

```bash
node --test tests/ssh-routing.test.mjs
bash scripts/bootstrap/test-bootstrap.sh
herdr machine list
ssh -o BatchMode=yes wykh32j-deb hostname
ssh -o BatchMode=yes wykh32j-wifi hostname
ssh -o BatchMode=yes wykh32j hostname
```

The automated transport tests simulate first-route success, error/timeout
fallback, both routes unavailable, established-connection failure, and invalid
ports. Configuration tests check all six aliases and strict host trust.
A successful live connection alone does not prove the second address works;
`.104` requires a separate live observation when available.
