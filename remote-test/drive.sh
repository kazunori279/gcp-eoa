#!/bin/bash
# drive.sh — send one workshop step to the persistent agy session and return.
#   1. pulls the exact prompt text for <module>/<blockid> from the extracted prompts JSON
#   2. ships it to the workstation (base64, to survive quoting)
#   3. launches agysend.sh DETACHED on the remote (nohup) so it survives tunnel drops
#
# Usage: ./drive.sh <module> <blockid> <stepname> [max_seconds] [stable_seconds]
#   e.g. ./drive.sh m0 ctx-combined m0s2 360 15
# Then track it with:  ./poll.sh m0s2     (or tail -f /tmp/agy-local.log)
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/config.sh"

MOD="$1"; BID="$2"; STEP="$3"; MAX="${4:-900}"; STABLE="${5:-15}"
PROMPTS="${WS_PROMPTS_JSON:-/tmp/agy-prompts/all.json}"

python3 -c "import json;d=json.load(open('$PROMPTS'));print([x for x in d['$MOD'] if x['id']=='$BID'][0]['text'])" > /tmp/p_$STEP.txt
echo "--- prompt ($STEP) chars: $(wc -c </tmp/p_$STEP.txt) ---"; head -c 200 /tmp/p_$STEP.txt; echo " ..."

P=$(base64 < /tmp/p_$STEP.txt | tr -d '\n')
"$DIR/rsh" "echo '$P'|base64 -d>/tmp/p_$STEP.txt; nohup bash ~/agysend.sh /tmp/p_$STEP.txt $STEP $MAX $STABLE >/tmp/agysend_$STEP.out 2>&1 & echo launched_pid \$!"
