# Windows and WSL credential login

## Normal use

Open the managed Debian4 Windows Terminal tab, which explicitly launches `bash --login`. Only a visible local WSL interactive **login** shell starts unlocking automatically. When needed, one GPG passphrase prompt unlocks credentials and loads the existing SSH identity. The maximum login window is 20 hours. New terminals reuse it without extending SSH's deadline.

If cancelled or unsuccessful, the shell reports that credentials remain locked. Run `credential-unlock` from a visible interactive WSL shell to retry. This explicit command also works in non-login Bash, tmux and interactive SSH sessions. SSH logins do not auto-unlock; neither do ordinary nested shells. Do not enter passphrases into agent transcripts.

Windows PowerShell and background commands do not own password prompts. AK retrieval outside the login coordinator uses cached GPG access or fails. Direnv exports only the existing allowlist and cannot trigger pinentry. Restic's proposed provider likewise requests cached-only access.

## Ownership

- `dot_bashrc.tmpl` supplies the standard Bash entrypoint and loads `~/.bashrc_custom`; it no longer embeds a duplicate custom configuration.
- `dot_bashrc_custom` discovers the SSH agent in visible shells, but automatically calls credential login only for local login shells. Direnv remains cached-only.
- `scripts/configure-windows-terminal.ps1` manages Debian4's explicit login-Bash launch without imposing Bash on other distros such as Alpine.
- `dot_local/lib/credential-login.sh` owns prompt eligibility, serialization and the fixed deadline.
- `dot_local/lib/credential-agent.sh` owns the persistent OpenSSH agent and key loading.
- AK's `bin/ak` permits pinentry only for the coordinator's explicit `AK_INTERACTIVE_UNLOCK=1` opt-in with a usable terminal. Other `get` calls fail promptly if locked.
- `windows-env` transports noninteractive commands. It is not another login/authentication workflow.

The existing GPG key, SSH identity and encrypted AK store are unchanged. No password is written into the session record.

## Timing and restart behavior

The GPG configuration retains 72,000-second default and maximum cache limits. The login coordinator starts a known window by restarting the user's GPG agent when there is no valid session record or the old window has expired. This clears old cached passphrases, not keys or encrypted files. Existing GPG operations can fail during that reset; it is deliberately limited to starting a new visible-login window.

The deadline is measured from before the prompt, using monotonic uptime and boot identity. Time spent answering the prompt consumes part of the window, so SSH cannot receive an extra 20 hours after a long prompt. It is a maximum shared window, not a claim that the two independent agents expire in the same millisecond.

Opening another terminal does not reload an already-loaded SSH key. If the key needs reloading within the window, it receives only the remaining lifetime. The session record also identifies the GPG agent process and start time; a detected restart causes a fresh window at the next visible login. This is not a background monitor: manually killing GPG mid-session does not immediately remove a key from the separate SSH agent. Its original deadline still applies.

## Why the old startup hung

WSL's systemd integration starts an internal `login -f <user>` session. An internal shell can be interactive and have a pseudo-terminal while its terminal type is `dumb`. Those two checks alone did not distinguish it from a real user terminal.

The observed hidden chain was `init-systemd -> login -> bash -> direnv -> ak -> gpg -> pinentry`, while a visible terminal waited behind it during SSH loading. Hidden/headless shells now do not start credential login or direnv. AK's cached-only default additionally protects background consumers and already-running old shells.

Reference: https://github.com/microsoft/WSL/blob/master/doc/docs/technical-documentation/systemd.md#user-sessions

## Validation

From WSL, with the reviewed AK source path:

```bash
bash tests/credential-agent/run.sh /path/to/ak/bin/ak
bash scripts/bootstrap/test-bootstrap.sh
```

The suite checks PTY visibility, fixed/remaining SSH lifetime, expiry, failed unlock and concurrent logins. A real-agent fixture uses its own GPG keyring, SSH key, synthetic pinentry and five-second cache. It never clears the operator's agent. Production cold-start and visible passphrase entry still require owner observation; the tests do not shut down WSL.

Apply only the reviewed `.bashrc`, `.bashrc_custom` and credential helper targets through chezmoi. A source-file edit is not evidence of deployment. Do not run a blanket apply to pick up unrelated pending backup work.

## Deployment evidence — 8 September 2026

Login-only follow-up: Debian4's Windows Terminal command is now `wsl.exe -d Debian4 -u jack --exec bash --login`. Automatic entry excludes SSH sessions and non-login shells; `credential-unlock` remains available there explicitly. Targeted chezmoi apply updated only the custom settings and login helper. The current agents/session deadline were not reset. Rollback is under `~/.local/state/credential-login-fix/login-only.V5T4Bv`; the Windows settings backup is under `%LOCALAPPDATA%/CredentialLoginFix`. Windows and Debian4 chezmoi sources were synchronized for the startup change.

The expanded credential suite, real-agent expiry fixture, bootstrap suite and Windows Terminal tests passed. ShellCheck and `git diff --check` passed. PSScriptAnalyzer reported the same nine pre-existing warnings on both the committed Terminal helper/tests and the changed versions; no clean-lint claim is made for those files.

The targeted startup files and AK cached-only policy were applied in Debian4. Deployed custom settings, login helper and AK executable were independently hashed; `.bashrc` matches its current chezmoi rendering. Rollback files are retained at `/home/jack/.local/state/credential-login-fix/rollback.S7d3H2`.

The previously identified hidden direnv chain was cancelled after ancestry checks, without stopping WSL or disabling SSH loading. Running the deployed `.bashrc` under a hidden-style `TERM=dumb` PTY returned successfully; no pending GPG/pinentry processes remained at that check.

The complete credential-agent suite, bootstrap suite, focused ShellCheck and both repository diff checks passed. The canonical backup fast gate also passed, with log `/var/tmp/credential-login-fast.V7Bwxt.log`. Real owner passphrase entry in a new visible terminal and a full WSL cold start have not been observed after deployment. No backup credential deployment, plaintext-password removal or backup capture was performed as part of this startup fix.
