#!/bin/bash
# Capture Pi's startup resource list from representative directories.
# No prompt is sent and no session is saved.
set -euo pipefail
OUT=/home/jack/work/agent-instruction-audit/pi-discovery-runtime.txt
: > "$OUT"
for cwd in /home/jack /home/jack/github/agent-skills /home/jack/github/mkdocs-material-test /home/jack/projects/heatpump-analysis /home/jack/github/life_cycle/controller_board; do
  raw=$(mktemp)
  clean=$(mktemp)
  printf '## cwd=%s\n' "$cwd" >> "$OUT"
  (cd "$cwd" && timeout 5s script -q -c 'PI_OFFLINE=1 pi --offline --no-session --no-approve' "$raw" >/dev/null 2>&1) || true
  # Remove terminal control sequences and carriage returns; retain resource metadata only.
  perl -pe 's/\e\][^\a]*(?:\a|\e\\)//g; s/\e\[[0-?]*[ -\/]*[@-~]//g; s/\r//g' "$raw" > "$clean"
  awk '
    { sub(/[[:space:]]+$/, "") }
    /^\[Context\]$|^\[Skills\]$|^\[Prompts\]$|^\[Extensions\]$/{show=1; print; next}
    show && /^$/{print; show=0; next}
    show {print}
  ' "$clean" >> "$OUT"
  printf '\n' >> "$OUT"
  rm -f "$raw" "$clean"
done
printf 'Wrote metadata-only runtime resource evidence to %s\n' "$OUT"
