# Production backup-health state decision packet

**Status:** approved production-state contract. The controller approved all recommended values and clauses. This approval settles policy documentation only; it does not authorize implementation, deployment, state writes, task changes, backup execution, commit, or push.

## Evidence and fixed constraints

The Phase 2 shadow coordinator proves projected consecutive counters, exact threshold crossings, success resets, awake-time interval handling, lock deferral, and backup-gated maintenance in disposable fixtures. It does not persist state or invoke production adapters. See [`TESTING.md`](TESTING.md).

The Phase 1 state helper already provides a versioned secret-free state shape, rejects unknown schema versions, and writes a same-directory temporary JSON file before replacement. The production adapter still needs stricter field validation, durable cross-process tests, and fault-injection evidence; the existing helper alone is not acceptance evidence for this contract.

The following constraints are already settled by [`LAPTOP-SCHEDULING-PLAN.md`](LAPTOP-SCHEDULING-PLAN.md):

- Count only completed backup attempts at eligible resume/login/unlock or 15-minute awake-time opportunities. A skipped periodic event, suspension, overlap refusal, or maintenance result does not advance either health counter.
- `Changed` and `NoChange` reset both counters to zero.
- `Failed` increments consecutive failures and resets deferrals; `DeferredLock` increments consecutive deferrals and resets failures.
- A lock deferral remains due, is not an immediate warning, and blocks maintenance for that coordinator run.
- Unknown state schemas fail closed. Credentials never belong in coordinator state.

## Warning threshold choices

A threshold is the attempt number that first produces `AttentionRequired`. It is not elapsed wall-clock time.

| Threshold | Observable consequence with periodic opportunities only | Assessment |
|---|---|---|
| 1 | Warn on the first observed failure or lock deferral | Reject: contradicts the requirement for repeated outcomes and makes one transient lock user-facing. |
| 2 | Warn on the second consecutive outcome, normally about 15 awake minutes after the first | Smallest policy that detects repetition while allowing one clean retry. |
| 3 | Warn on the third consecutive outcome, normally about 30 awake minutes after the first | Quieter, but delays warning by another recovery-point interval. |
| 4 | Warn on the fourth consecutive outcome, normally about 45 awake minutes after the first | No current evidence justifies this additional delay. |

Login, unlock, and resume are independently eligible opportunities, so they can reach a threshold sooner than the periodic-only examples. Suspension pauses the periodic awake clock and creates no counter increments; it must never cause a burst of replayed attempts.

**Approved decision:** `FailureWarningThreshold = 2` and `DeferralWarningThreshold = 2`. This is the smallest policy consistent with “repeated,” gives a transient result one retry, and reports a continuing protection or lock problem at the next eligible opportunity. The values happen to match Phase 2 fixture data, but the fixture value is not the reason or evidence for this decision.

Changing either value requires a new controller decision and updated observable-consequence tests.

## Configuration ownership and validation

**Approved decision:** own one reviewed JSON policy file at `scripts/wsl-backup/home/WslHomeSchedulingPolicy.json` and have setup deploy an exact copy beside the Windows-local controller under `%LOCALAPPDATA%\WSLHomeRestic`. The installed coordinator receives that one path; Task Scheduler arguments and source code must not duplicate threshold values.

The eventual loader must require:

- a JSON object with an exact supported schema version;
- `FailureWarningThreshold` and `DeferralWarningThreshold` as JSON integers in the approved range `2..3`;
- `NotificationSuppressionHours` as a JSON integer equal to the approved value;
- rejection of missing, null, string, fractional, out-of-range, duplicate, or unknown policy fields;
- a source/deployed policy hash in read-only status so drift is observable.

Alternatives are a manually owned local policy file, which creates avoidable drift, or Task Scheduler arguments, which duplicate policy and complicate read-back. Neither is recommended.

## Persistence and state transitions

Use `%LOCALAPPDATA%\WSLHomeRestic\coordinator-state.json`. Initialization is an explicit setup action; the coordinator must fail closed if state is absent, malformed, or from an unknown schema.

For each eligible backup opportunity:

1. Acquire the coordinator lock and read one strictly validated state generation.
2. Atomically record a bounded pending attempt before invoking the fixed backup command.
3. Classify the observed exit/result contract and calculate projected counters using the fixed rules above.
4. Write complete JSON to a unique temporary file in the same directory, flush it, strictly re-read it, then atomically replace the prior state. Never update in place.
5. Only the successful replacement makes the result and projected counters current. Clean temporary files in `finally`.

The state must include a monotonic generation and pending-attempt identity. Do not infer success from a missing process or from backup side effects. If execution stops after recording pending but before committing a result, retain the previous completed counters, record/recover the interrupted attempt as still due, and retry at a later eligible opportunity. Do not increment failure or deferral counters without an observed classified result. A retry may safely produce `NoChange`, which then resets both counters.

On a malformed primary state, unknown schema, impossible mixed counters, generation regression, or mismatched pending metadata: preserve the file for diagnosis, run no backup or maintenance command, emit a state-health diagnostic through the existing notification boundary, and require an explicit recovery action. Do not silently guess, reset, or downgrade schema. Atomic-replacement interruption must leave either the prior valid generation or the complete new generation readable.

## Notification suppression choices

**Approved decision:** retain the existing tested six-hour suppression window for the same signature during one uninterrupted health episode.

- The first threshold crossing notifies.
- The same failure/deferral signature is suppressed for less than six hours and may notify again exactly at six hours.
- A changed signature notifies immediately.
- `Changed` or `NoChange` ends the health episode and clears its suppression identity, so a later independent episode can notify immediately even within six wall-clock hours.
- Suspension neither expires an awake-time threshold nor creates a notification, but notification suppression itself remains wall-clock based.

A shorter window adds noise without evidence; 12 or 24 hours delays a persistent protection warning. Changing six hours requires a separate reason and boundary test.

## Disposable acceptance contract for the eventual adapter

Run every test with a unique temporary state/policy directory, a fake fixed backup executable, and no production environment paths. Launch separate `pwsh.exe` processes where cross-run persistence is under test. Each test must assert command count, result class, complete state JSON, generation, counters, pending metadata, notification record, and absence of production side effects.

1. **Policy validation:** accept the exact approved policy; reject absent, malformed, unknown-schema, extra-field, string, fractional, null, below-range, and above-range values before invoking the fake backup.
2. **Eligible opportunities only:** skipped periodic events, suspension, overlap refusal, and maintenance outcomes leave counters and generation-of-last-completed-attempt unchanged.
3. **Failure boundary across processes:** start at zero, return a real failure from separate eligible invocations, remain non-alerting after attempt 1, and alert exactly on the configured attempt. Verify periodic-only elapsed awake consequences.
4. **Deferral boundary across processes:** exit `75`/`Lock` remains due, blocks maintenance, remains non-alerting before the boundary, and alerts exactly at the configured attempt.
5. **Mutual exclusion and reset:** failure resets deferrals, deferral resets failures, and both `Changed` and `NoChange` reset both counters and end the notification episode.
6. **Strict result contract:** reject exit/result mismatches without committing invented success, failure, or deferral state.
7. **Atomic replacement faults:** inject termination before temporary write, after write, after flush/validation, and immediately before replacement. On restart, read the complete old generation; after successful replacement, read the complete new generation. Never accept partial JSON, and remove abandoned temporary files through explicit recovery/cleanup.
8. **Post-replacement interruption:** terminate immediately after replacement and prove the new valid generation is authoritative on restart.
9. **Interrupted external attempt:** terminate after pending state is durable and after the fake command side effect but before result commit. Restart without inferring success, keep work due, retry once, and commit the observed retry result.
10. **Corrupt and unknown state:** preserve the bad file, invoke no backup or maintenance, emit one diagnostic subject to suppression, and require explicit recovery rather than automatic reset or backup-file fallback.
11. **Notification episodes:** prove first notification, suppression just before six hours, repeat exactly at six hours, immediate notification for a changed signature, and immediate notification after a successful reset starts a later episode.
12. **Production isolation:** fail the test if WSL, Restic, Task Scheduler, `msg.exe`, production `%LOCALAPPDATA%\WSLHomeRestic`, credentials, or the failed full-data-check marker are touched.

Use semantic mutations to invert the threshold boundary, count an ineligible opportunity, preserve counters after success, accept malformed state, infer success after interruption, replace state non-atomically, suppress a new episode, or allow maintenance after deferral. Each mutant must fail at its named retained assertion rather than through syntax or harness errors.

## Approved decision record

The controller approved, without amendment:

- failure warning on the second consecutive eligible real failure;
- lock-deferral warning on the second consecutive eligible lock deferral;
- suspension neither increments nor resets either counter, even when it lasts days or weeks;
- six-hour wall-clock suppression for the same signature within one uninterrupted health episode;
- immediate eligibility for a changed signature or a new episode after successful reset;
- one tracked JSON policy deployed beside the Windows controller with strict validation and observable drift;
- the atomic persistence, fail-closed recovery, disposable acceptance-test, and semantic-mutation contract above.

A later bounded authorization integrated the source-only adapter at commit `1e2b97a`, satisfying this contract's disposable evidence gate. Phase 3 source-only consent was subsequently integrated at commit `6a84654`.

The later OS-ownership correction supersedes this Windows adapter as the routine production scheduler target: backup opportunity, health, due state, and routine Restic execution belong inside Linux and must not be polled by Windows. This document remains the approved behavioral evidence for counters, atomic state, and notification episodes; those contracts must be translated deliberately into Linux rather than deploying the Windows adapter unchanged. Windows remains eligible only for visible consent, power, idle-sleep inhibition, and whole-system export. Production migration and operations remain separately authorized.
