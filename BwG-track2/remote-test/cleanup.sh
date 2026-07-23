#!/bin/bash
# cleanup.sh — remove ALL workshop remnants from the target before a fresh M0 run.
#
# WHY: the Cloud Shell target can be ANY project, which may carry leftovers from a prior
# run — local files, a deployed Agent Engine, a Gemini Enterprise agent registration, a
# Model Armor template, and a populated DK MCP config. A partial state makes the next run
# non-representative (e.g. M0 Step 1's overwrite isn't exercised, M5 registers a duplicate).
#
# SAFETY: this deletes ONLY workshop-named resources — reasoning engines whose displayName
# is exactly "transit-assistant", GE agents named "Transit-Crisis Agent", and the Model
# Armor template "transit-shield". It NEVER blanket-deletes (shared projects often hold
# unrelated engines/apps). GE app *containers* are left in place (M5 re-registers into them);
# pass --apps to also delete workshop-named GE app engines (transit-crisis*).
#
# Usage:  ./cleanup.sh            # local + cloud remnants (safe defaults)
#         ./cleanup.sh --apps     # also delete workshop-named GE app engines
#         ./cleanup.sh --keep-backups   # keep ~/preflight-backup-* dirs
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/config.sh"
DEL_APPS=0; KEEP_BK=0
for a in "$@"; do case "$a" in --apps) DEL_APPS=1;; --keep-backups) KEEP_BK=1;; esac; done

WS_ENGINE_NAME="transit-assistant"      # reasoning-engine displayName the scaffold pins
GE_AGENT_NAME="Transit-Crisis Agent"    # GE registered-agent displayName from M5
MA_TEMPLATE="transit-shield"            # Model Armor template from M3
REGIONS="us-east1 us-central1 us-west1 europe-west1"

# Build the remote payload (runs on Cloud Shell, where gcloud/ADC live).
read -r -d '' REMOTE <<REMOTE_EOF
set -uo pipefail
PROJECT=\$(gcloud config get-value project 2>/dev/null)
PNUM=\$(gcloud projects describe "\$PROJECT" --format='value(projectNumber)' 2>/dev/null)
TOK=\$(gcloud auth print-access-token 2>/dev/null)
H=(-H "Authorization: Bearer \$TOK" -H "X-Goog-User-Project: \$PROJECT")
echo "[cleanup] project=\$PROJECT number=\$PNUM"

echo "[cleanup] stop agy + background jobs"
tmux kill-session -t agy 2>/dev/null
pkill -f 'adk web' 2>/dev/null; pkill -f 'agents-cli playground' 2>/dev/null
pkill -f simulate_crisis.py 2>/dev/null; pkill -f 'adk eval' 2>/dev/null
pkill -f 'tail -.*agy-session.log' 2>/dev/null; true

echo "[cleanup] delete reasoning engines named '$WS_ENGINE_NAME'"
for R in $REGIONS; do
  LIST=\$(curl -s "\${H[@]}" "https://\$R-aiplatform.googleapis.com/v1/projects/\$PROJECT/locations/\$R/reasoningEngines")
  for E in \$(printf '%s' "\$LIST" | python3 -c "import sys,json;d=json.load(sys.stdin);[print(e['name']) for e in d.get('reasoningEngines',[]) if e.get('displayName')=='$WS_ENGINE_NAME']" 2>/dev/null); do
    echo "  deleting \$E"
    curl -s -X DELETE "\${H[@]}" "https://\$R-aiplatform.googleapis.com/v1/\$E?force=true" -o /dev/null -w "    HTTP %{http_code}\n"
  done
done

echo "[cleanup] delete GE registered agents named '$GE_AGENT_NAME'"
ENGINES=\$(curl -s "\${H[@]}" "https://global-discoveryengine.googleapis.com/v1alpha/projects/\$PNUM/locations/global/collections/default_collection/engines")
for ENG in \$(printf '%s' "\$ENGINES" | python3 -c "import sys,json;d=json.load(sys.stdin);[print(e['name']) for e in d.get('engines',[])]" 2>/dev/null); do
  AG=\$(curl -s "\${H[@]}" "https://global-discoveryengine.googleapis.com/v1alpha/\$ENG/assistants/default_assistant/agents")
  for A in \$(printf '%s' "\$AG" | python3 -c "import sys,json;d=json.load(sys.stdin);[print(a['name']) for a in d.get('agents',[]) if a.get('displayName')=='$GE_AGENT_NAME']" 2>/dev/null); do
    echo "  deleting \$A"
    curl -s -X DELETE "\${H[@]}" "https://global-discoveryengine.googleapis.com/v1alpha/\$A" -o /dev/null -w "    HTTP %{http_code}\n"
  done
  if [ "$DEL_APPS" = "1" ]; then
    case "\$ENG" in *"/engines/transit-crisis"*)
      echo "  deleting GE app \$ENG"
      curl -s -X DELETE "\${H[@]}" "https://global-discoveryengine.googleapis.com/v1alpha/\$ENG" -o /dev/null -w "    HTTP %{http_code}\n";;
    esac
  fi
done

echo "[cleanup] delete Model Armor template '$MA_TEMPLATE' (us-central1)"
gcloud config set api_endpoint_overrides/modelarmor "https://modelarmor.us-central1.rep.googleapis.com/" >/dev/null 2>&1
(gcloud model-armor templates delete "$MA_TEMPLATE" --location=us-central1 --project="\$PROJECT" --quiet 2>/dev/null \
  || gcloud beta model-armor templates delete "$MA_TEMPLATE" --location=us-central1 --project="\$PROJECT" --quiet 2>/dev/null) \
  && echo "  deleted" || echo "  (none / already gone)"
gcloud config unset api_endpoint_overrides/modelarmor >/dev/null 2>&1

echo "[cleanup] remove local workshop artifacts"
rm -rf ~/transit-* ~/plan.md ~/data ~/agy-session.log ~/agy-session.log.bak ~/.aylogs/* \
       ~/.gemini/antigravity-cli/conversations/* ~/.gemini/antigravity-cli/brain/* 2>/dev/null
[ "$KEEP_BK" = "1" ] || rm -rf ~/preflight-backup-* 2>/dev/null

echo "[cleanup] reset DK MCP config + settings permissions to FRESH state"
: > ~/.gemini/config/mcp_config.json 2>/dev/null
: > ~/.gemini/antigravity-cli/mcp_config.json 2>/dev/null
python3 -c "import json,os; p=os.path.expanduser('~/.gemini/antigravity-cli/settings.json'); d=json.load(open(p)); d.pop('permissions',None); json.dump(d,open(p,'w'),indent=2)" 2>/dev/null

echo "[cleanup] verify clean:"
echo -n "  reasoning engines named '$WS_ENGINE_NAME': "; N=0
for R in $REGIONS; do
  N=\$((N+\$(curl -s "\${H[@]}" "https://\$R-aiplatform.googleapis.com/v1/projects/\$PROJECT/locations/\$R/reasoningEngines" | python3 -c "import sys,json;print(sum(1 for e in json.load(sys.stdin).get('reasoningEngines',[]) if e.get('displayName')=='$WS_ENGINE_NAME'))" 2>/dev/null || echo 0)))
done; echo "\$N (expect 0)"
echo -n "  local transit-*/plan.md/data present: "; ls -d ~/transit-* ~/plan.md ~/data 2>/dev/null | wc -l | tr -d ' ';
echo -n "  backups present: "; ls -d ~/preflight-backup-* 2>/dev/null | wc -l | tr -d ' '
echo -n "  mcp_config bytes: "; wc -c < ~/.gemini/antigravity-cli/mcp_config.json 2>/dev/null
echo -n "  settings permissions count: "; grep -c permissions ~/.gemini/antigravity-cli/settings.json 2>/dev/null
echo "[cleanup] done."
REMOTE_EOF

B=$(printf '%s' "$REMOTE" | base64 | tr -d '\n')
"$DIR/rsh" "echo '$B' | base64 -d > /tmp/ws_cleanup.sh && bash /tmp/ws_cleanup.sh"
