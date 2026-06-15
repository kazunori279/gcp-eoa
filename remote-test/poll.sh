#!/bin/bash
# poll.sh — one-shot status check for a step: shows the live agy pane and whether it's done.
# Usage: ./poll.sh <stepname>
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/config.sh"
STEP="$1"
"$DIR/rsh" "echo '=== pane ==='; tmux capture-pane -t agy -p | sed -e 's/\x1b\[[0-9;?]*[a-zA-Z]//g' | grep -v '^\$' | tail -22; echo; if grep -q '\[done step=$STEP' ~/$WS_SESSION_LOG; then echo STEP_DONE; else echo STEP_RUNNING; fi"
