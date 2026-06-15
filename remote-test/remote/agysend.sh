#!/bin/bash
# agysend.sh (runs ON the workstation) — send ONE prompt to the live agy tmux session,
# wait for it to finish, and append the exchange (prompt + full trajectory) to the transcript.
#
# Key techniques:
#   * Multi-line prompts are injected with `tmux set-buffer` + `paste-buffer -p` (bracketed
#     paste) so embedded newlines do NOT submit early; a single Enter then submits.
#   * Completion is detected by SCREEN STABILITY: poll capture-pane; when the rendered
#     screen stops changing for <stable> seconds, agy is done (idle = empty ">" + status bar).
#   * The transcript captures agy's trajectory: tool calls render as `● Tool(args)` and
#     reasoning as `▸ Thought for Ns`.
#
# Usage: agysend.sh <promptfile> <stepid> [max_seconds] [stable_seconds]
set -uo pipefail
PFILE="$1"; STEP="$2"; MAX="${3:-900}"; STABLE="${4:-12}"
LOG="$HOME/agy-session.log"
clean(){ sed -e 's/\x1b\[[0-9;?]*[a-zA-Z]//g' -e 's/\r//g'; }

base=$(tmux capture-pane -t agy -pS -32000 | clean)
basen=$(printf '%s\n' "$base" | wc -l)

{ echo; echo "################## STUDENT -> AGY [$STEP] $(date '+%F %T') ##################"
  echo "--- PROMPT ---"; cat "$PFILE"; echo; } >> "$LOG"

tmux set-buffer -b agyp "$(cat "$PFILE")"
tmux paste-buffer -p -b agyp -t agy
sleep 1
tmux send-keys -t agy Enter

last=""; stable=0; elapsed=0; iv=5
sleep 4; elapsed=4
while [ $elapsed -lt $MAX ]; do
  cur=$(tmux capture-pane -t agy -pS -32000 | clean)
  if [ "$cur" = "$last" ]; then
    stable=$((stable+iv)); [ $stable -ge $STABLE ] && break
  else stable=0; last="$cur"; fi
  sleep $iv; elapsed=$((elapsed+iv))
done

full=$(tmux capture-pane -t agy -pS -32000 | clean)
resp=$(printf '%s\n' "$full" | sed -n "$((basen+1)),\$p")
{ echo "--- RESPONSE (new pane content) ---"; printf '%s\n' "$resp"
  echo "[done step=$STEP elapsed=${elapsed}s stable=${stable}s]"; } >> "$LOG"
printf '%s\n' "$resp"
