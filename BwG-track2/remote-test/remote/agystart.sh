#!/bin/bash
# agystart.sh (runs ON the workstation) — (re)start the persistent agy session inside tmux.
# tmux gives agy a real PTY (it's a full-screen TUI) AND keeps it alive across SSH/tunnel
# drops, so the single conversation survives. Requires: tmux, an authenticated agy.
set -uo pipefail
tmux kill-session -t agy 2>/dev/null
sleep 1
tmux new-session -d -s agy -x 200 -y 50
# --dangerously-skip-permissions: auto-approve tool calls (headless, throwaway lab only)
# --add-dir ~: make agy operate on the project dir, not its internal scratch dir
tmux send-keys -t agy "cd ~ && agy --dangerously-skip-permissions --add-dir ~" Enter
for i in $(seq 1 30); do
  sleep 2
  if tmux capture-pane -t agy -p | grep -q "for shortcuts"; then echo "AGY READY after $((i*2))s"; break; fi
done
tmux capture-pane -t agy -p | sed -e 's/\x1b\[[0-9;?]*[a-zA-Z]//g' | grep -v '^$' | tail -6
