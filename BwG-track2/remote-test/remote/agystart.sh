#!/bin/bash
# agystart.sh (runs ON the remote) — (re)start the persistent agy session inside tmux.
# tmux gives agy a real PTY (it's a full-screen TUI) AND keeps it alive across SSH/tunnel
# drops, so the single conversation survives. Requires: tmux, an authenticated agy.
#
# TALL PANE (AGY_ROWS, default 1000): agy renders in-place and only spills into tmux
# scrollback when a step's output exceeds the viewport — and that scroll-during-streaming
# pollutes history with partial spinner frames, wrecking the capture. A tall pane means a
# step almost never scrolls, so agysend can grab ONE clean final frame. Override per start:
#   ./rsh "AGY_ROWS=1500 bash ~/agystart.sh"
set -uo pipefail
ROWS="${AGY_ROWS:-1000}"
COLS="${AGY_COLS:-200}"
tmux kill-session -t agy 2>/dev/null
sleep 1
tmux new-session -d -s agy -x "$COLS" -y "$ROWS"
# pin the size so a read-only `tmux attach` viewer can't reflow the pane agysend captures
# (no-ops on old tmux, e.g. Cloud Shell's 2.1 — the -x/-y at creation still holds while detached)
tmux set-option -t agy window-size manual 2>/dev/null
tmux set-option -t agy aggressive-resize off 2>/dev/null
tmux resize-window -t agy -x "$COLS" -y "$ROWS" 2>/dev/null
# --dangerously-skip-permissions: auto-approve tool calls (headless, throwaway lab only)
# --add-dir ~: make agy operate on the project dir, not its internal scratch dir
tmux send-keys -t agy "cd ~ && agy --dangerously-skip-permissions --add-dir ~" Enter
for i in $(seq 1 30); do
  sleep 2
  if tmux capture-pane -t agy -p | grep -q "for shortcuts"; then echo "AGY READY after $((i*2))s (pane ${COLS}x${ROWS})"; break; fi
done
tmux capture-pane -t agy -p | sed -e 's/\x1b\[[0-9;?]*[a-zA-Z]//g' | grep -v '^$' | tail -6
