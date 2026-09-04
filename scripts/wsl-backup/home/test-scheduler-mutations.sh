#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source_path=$SCRIPT_DIR/wsl-home-scheduler
retained_test=$SCRIPT_DIR/test-scheduler.sh
root=$(mktemp -d "${TMPDIR:-/tmp}/wsl-home-scheduler-mutations.XXXXXX")
trap 'rm -rf "$root"' EXIT

names=(backup-gate retention-boundary malformed-state overlap-lock atomic-state)
# Mutation seams are literal source text.
# shellcheck disable=SC2016
olds=(
  '"$HOME_COMMAND" backup'
  'if [[ -z $last_retention ]] || ((NOW_EPOCH - last_retention >= RETENTION_INTERVAL_SECONDS)); then'
  "\${state_lines[0]} != 'schema_version=1'"
  'if ! flock -n 9; then'
  'mv -f -- "$temporary" "$STATE_PATH"'
)
# Replacements are literal source text.
# shellcheck disable=SC2016
news=(
  '"$HOME_COMMAND" backup || true'
  'if true; then'
  "\${state_lines[0]} != 'schema_version=99'"
  'if false; then'
  'cp -- "$temporary" "$STATE_PATH"'
)
patterns=(
  'backup failure propagates and blocks all later Linux-owned work'
  'retention remains not due before its exact Linux-owned boundary'
  'malformed scheduler state fails closed before backup'
  'overlap refusal runs no second Linux coordinator'
  'atomic scheduler state writes leave no temporary file'
)

for index in "${!names[@]}"; do
  candidate=$root/${names[index]}
  SOURCE=$source_path OLD=${olds[index]} NEW=${news[index]} OUTPUT=$candidate \
    perl -0 -e '
      use strict; use warnings;
      local $/; open my $in, "<", $ENV{SOURCE} or die $!; my $text=<$in>;
      my $count=()=$text =~ /\Q$ENV{OLD}\E/g;
      die "expected one mutation seam, found $count\n" unless $count == 1;
      $text =~ s/\Q$ENV{OLD}\E/$ENV{NEW}/;
      open my $out, ">", $ENV{OUTPUT} or die $!; print {$out} $text;
    '
  chmod +x "$candidate"
  bash -n "$candidate"
  set +e
  output=$(WSL_HOME_SCHEDULER_CANDIDATE=$candidate bash "$retained_test" 2>&1)
  code=$?
  set -e
  [[ $code -ne 0 ]] || { echo "Mutation survived: ${names[index]}" >&2; exit 1; }
  grep -F -- "${patterns[index]}" <<<"$output" >/dev/null || {
    echo "Mutation ${names[index]} failed at wrong seam; expected: ${patterns[index]}" >&2
    printf '%s\n' "$output" >&2
    exit 1
  }
  [[ $output != *'syntax error'* ]] || { echo "Mutation ${names[index]} was invalid" >&2; exit 1; }
  printf 'Killed mutation %s: %s\n' "${names[index]}" "${patterns[index]}"
done
printf 'WslHomeLinuxScheduler semantic mutations killed: %d\n' "${#names[@]}"
