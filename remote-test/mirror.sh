#!/bin/bash
# mirror.sh — stream the remote agy transcript down to a local file you can tail.
# Seeds with the existing transcript, then follows. Reconnects if the tunnel blips.
# Run in the background:  nohup ./mirror.sh >/dev/null 2>&1 &
# Then watch locally:     tail -f /tmp/agy-local.log
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/config.sh"

# seed with whatever already exists (ANSI stripped)
"$DIR/rsh" "cat ~/$WS_SESSION_LOG" 2>/dev/null \
  | sed -e 's/\x1b\[[0-9;?]*[a-zA-Z]//g' > "$WS_LOCAL_MIRROR"

# follow new lines; loop so a tunnel restart just re-attaches
while true; do
  "$DIR/rsh" "tail -n0 -F ~/$WS_SESSION_LOG" 2>/dev/null \
    | sed -u -e 's/\x1b\[[0-9;?]*[a-zA-Z]//g' -e 's/\r//g' >> "$WS_LOCAL_MIRROR"
  sleep 3
done
