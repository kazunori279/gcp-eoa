#!/bin/bash
# live.sh — continuously snapshot the agy tmux pane to a local file for LIVE viewing
# (tool calls + streaming output as they happen, ~2s fresh).
#
# Safe by design: it only runs read-only `tmux capture-pane`; it never attaches and never
# resizes the session, so it cannot disturb agysend's completion detection.
#
# Run:    nohup ./live.sh >/dev/null 2>&1 &
# Watch:  watch -n 1 cat /tmp/agy-live.txt
#
# (For the per-step clean transcript instead, use mirror.sh + `tail -f /tmp/agy-local.log`.
#  For a true live TUI, read-only attach:
#    ssh -p 2222 -i ~/.ssh/google_compute_engine -o StrictHostKeyChecking=no \
#        -o UserKnownHostsFile=/dev/null -t user@localhost "tmux attach -t agy -r" )
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/config.sh"
OUT="${1:-/tmp/agy-live.txt}"
while true; do
  "$DIR/rsh" "tmux capture-pane -t agy -p" 2>/dev/null \
    | sed -e 's/\x1b\[[0-9;?]*[a-zA-Z]//g' > "$OUT.tmp" 2>/dev/null && mv "$OUT.tmp" "$OUT"
  sleep 2
done
