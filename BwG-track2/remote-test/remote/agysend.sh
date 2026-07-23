#!/bin/bash
# agysend.sh (runs ON the remote) — send ONE prompt to the live agy tmux session, wait for
# it to finish, and append the exchange (prompt + agy's trajectory) to the transcript.
#
# Key techniques:
#   * Multi-line prompts are injected with `tmux set-buffer` + `paste-buffer -p` (bracketed
#     paste) so embedded newlines do NOT submit early; a single Enter then submits.
#   * Completion is detected by SCREEN STABILITY: poll capture-pane; when the rendered
#     screen stops changing for <stable> seconds, agy is done (idle = empty ">" + status bar).
#   * Capture: agy repaints in place (no alternate screen) and only spills to scrollback when
#     a step exceeds the viewport. agystart uses a TALL pane so a step renders in ONE clean
#     frame; we capture that frame (`capture-pane -p`) and slice out THIS step's response by
#     anchoring on the echoed prompt line (`> <prompt>`). If the step was so long it scrolled
#     off the top of even the tall pane, we fall back to the full scrollback (`-pS -32000`).
#   * The trajectory renders tool calls as `● Tool(args)` and reasoning as `▸ Thought for Ns`.
#
# Usage: agysend.sh <promptfile> <stepid> [max_seconds] [stable_seconds]
set -uo pipefail
PFILE="$1"; STEP="$2"; MAX="${3:-900}"; STABLE="${4:-20}"
LOG="$HOME/agy-session.log"
clean(){ sed -e 's/\x1b\[[0-9;?]*[a-zA-Z]//g' -e 's/\r//g'; }

{ echo; echo "################## STUDENT -> AGY [$STEP] $(date '+%F %T') ##################"
  echo "--- PROMPT ---"; cat "$PFILE"; echo; } >> "$LOG"

tmux set-buffer -b agyp "$(cat "$PFILE")"
tmux paste-buffer -p -b agyp -t agy
sleep 1
tmux send-keys -t agy Enter

# Wait for the rendered frame to stop changing (agy idle). Busy-guard: don't declare done while
# agy is actively generating — detected by "esc to cancel" in the status bar (present only during
# a live turn; it becomes "? for shortcuts" when agy returns to the prompt). Deliberately NOT
# matching:
#   * "Generating"/"Working" — these appear in agy's reasoning text ("Generating Plan File").
#   * "N task(s)" — agy's background-task tracker keeps STALE entries (e.g. after a killed
#     playground), which would pin the step busy forever. For genuine background steps
#     (deploy/sim/eval) the marker can still fire early; cross-check ground truth externally
#     (Vertex operation, task logs, API) — the harness does this.
last=""; stable=0; elapsed=0; iv=5
sleep 4; elapsed=4
while [ $elapsed -lt $MAX ]; do
  cur=$(tmux capture-pane -t agy -p | clean)
  busy=$(printf '%s' "$cur" | grep -c 'esc to cancel')
  if [ "$cur" = "$last" ] && [ "$busy" -eq 0 ]; then
    stable=$((stable+iv)); [ $stable -ge $STABLE ] && break
  else stable=0; last="$cur"; fi
  sleep $iv; elapsed=$((elapsed+iv))
done

# extract THIS step's response: prefer the clean single frame; fall back to full scrollback
frame=$(tmux capture-pane -t agy -p | clean)
hist=$(tmux capture-pane -t agy -pS -32000 | clean)
resp=$(FRAME="$frame" HIST="$hist" PFILE="$PFILE" python3 - <<'PY'
import os, re
pf = open(os.environ['PFILE']).read().splitlines()
first = pf[0].strip() if pf else ''

def is_sep(s):    return bool(re.fullmatch(r'[─\-]{20,}', s.strip()))
def is_status(s): return ('for shortcuts' in s) or ('esc to cancel' in s) or bool(re.search(r'Gemini.*Flash', s))

def strip_chrome(lines):
    # drop the trailing input box + status chrome (and blank padding) from the bottom
    L = list(lines)
    while L:
        s = L[-1]
        if (not s.strip()) or is_sep(s) or is_status(s) or s.strip() == '>':
            L.pop()
        else:
            break
    return L

def extract(lines):
    L = strip_chrome(lines)
    idx = -1
    for i, s in enumerate(L):
        t = s.lstrip()
        if t.startswith('>'):
            after = t[1:].strip()
            if after and (after == first or first.startswith(after) or after.startswith(first[:40])):
                idx = i
    if idx < 0:
        return None
    resp = L[idx + 1:]
    while resp and not resp[0].strip():  resp.pop(0)
    while resp and not resp[-1].strip(): resp.pop()
    return '\n'.join(resp)

r = extract(os.environ['FRAME'].splitlines())
if r is None:
    r = extract(os.environ['HIST'].splitlines())
if r is None:
    r = '[capture: prompt echo not found; cleaned final frame follows]\n' + \
        '\n'.join(strip_chrome(os.environ['FRAME'].splitlines()))
print(r)
PY
)
{ echo "--- RESPONSE (trajectory) ---"; printf '%s\n' "$resp"
  echo "[done step=$STEP elapsed=${elapsed}s stable=${stable}s]"; } >> "$LOG"
printf '%s\n' "$resp"
