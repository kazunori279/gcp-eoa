#!/bin/bash
# setlab.sh — point the remote-test harness at a new Qwiklabs lab in ONE command.
#
# usage:  ./setlab.sh <project-id> [student-account@qwiklabs.net]
#
# It: sets the gcloud account+project, auto-discovers the workstation, rewrites
# config.sh, provisions the SSH key, (re)starts the tunnel supervisor, verifies
# the channel, installs tmux + deploys the remote scripts, and checks agy auth.
#
# Prereq the human still owns: `gcloud auth login` (the student account must
# already be in `gcloud auth list`), and the one-time `agy` OAuth on the
# workstation (this script tells you if it's missing).
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Pick up CLOUDSDK_CONFIG (isolated gcloud profile) so this script's gcloud
# auth/config/workstations calls hit the lab profile, not your personal one.
source "$DIR/config.sh"
PROJECT="${1:?usage: setlab.sh <project-id> [student-account@qwiklabs.net]}"
ACCOUNT="${2:-}"

say(){ echo "[setlab] $*"; }

# 1. gcloud account + project ------------------------------------------------
if [ -n "$ACCOUNT" ]; then
  gcloud config set account "$ACCOUNT" >/dev/null 2>&1 \
    || { echo "ERROR: '$ACCOUNT' is not in 'gcloud auth list' — run: gcloud auth login"; exit 1; }
fi
gcloud config set project "$PROJECT" >/dev/null 2>&1 \
  || { echo "ERROR: cannot set project '$PROJECT'"; exit 1; }
say "account=$(gcloud config get-value account 2>/dev/null)  project=$PROJECT"

# 2. discover the workstation ------------------------------------------------
say "discovering workstation in $PROJECT ..."
LIST=$(gcloud workstations list --project="$PROJECT" 2>&1)
echo "$LIST" | grep -q '^NAME' || { echo "ERROR: 'gcloud workstations list' failed:"; echo "$LIST"; exit 1; }
# prefer a RUNNING workstation; else the first listed
ROW=$(echo "$LIST" | awk 'NR>1 && $5=="RUNNING"{print; exit}')
[ -z "$ROW" ] && ROW=$(echo "$LIST" | awk 'NR>1 && NF>=4{print; exit}')
[ -z "$ROW" ] && { echo "ERROR: no workstation found in $PROJECT"; exit 1; }
WS_NAME=$(echo "$ROW"   | awk '{print $1}')
WS_CONFIG=$(echo "$ROW" | awk '{print $2}')
WS_CLUSTER=$(echo "$ROW"| awk '{print $3}')
WS_REGION=$(echo "$ROW" | awk '{print $4}')
say "workstation=$WS_NAME  cluster=$WS_CLUSTER  config=$WS_CONFIG  region=$WS_REGION"

# 3. rewrite config.sh -------------------------------------------------------
CFG="$DIR/config.sh"
sed -i.bak \
  -e "s|^export WS_PROJECT=.*|export WS_PROJECT=\"$PROJECT\"|" \
  -e "s|^export WS_CLUSTER=.*|export WS_CLUSTER=\"$WS_CLUSTER\"|" \
  -e "s|^export WS_CONFIG=.*|export WS_CONFIG=\"$WS_CONFIG\"|" \
  -e "s|^export WS_REGION=.*|export WS_REGION=\"$WS_REGION\"|" \
  -e "s|^export WS_NAME=.*|export WS_NAME=\"$WS_NAME\"|" \
  "$CFG" && rm -f "$CFG.bak"
say "config.sh updated"

# 4. provision the SSH key (one-shot gcloud ssh) -----------------------------
say "provisioning SSH key (one-shot gcloud workstations ssh) ..."
gcloud workstations ssh --project="$PROJECT" --cluster="$WS_CLUSTER" \
  --config="$WS_CONFIG" --region="$WS_REGION" "$WS_NAME" \
  --command="echo provisioned" >/dev/null 2>&1 \
  && say "SSH key provisioned" \
  || say "WARN: key provisioning had issues (check gcloud auth / workstation state)"

# 5. (re)start the tunnel supervisor ----------------------------------------
pkill -f 'tunnel_sup.sh' 2>/dev/null; pkill -f 'start-tcp-tunnel' 2>/dev/null
rm -f "$HOME/.ssh/cm-agy.sock"; sleep 1
nohup "$DIR/tunnel_sup.sh" >/tmp/tunnel_sup.log 2>&1 &
say "tunnel supervisor restarted (pid $!) — waiting for it to come up ..."
sleep 8

# 6. verify the channel ------------------------------------------------------
if ! bash "$DIR/rsh" "echo OK" >/dev/null 2>&1; then
  sleep 6
  bash "$DIR/rsh" "echo OK" >/dev/null 2>&1 \
    || { echo "ERROR: channel not up. Check /tmp/tunnel_sup.log and /tmp/tunnel_raw.log, then retry ./rsh 'echo alive'"; exit 1; }
fi
say "✅ channel up on $(bash "$DIR/rsh" 'hostname' 2>/dev/null)"

# 7. remote prep: tmux + deploy scripts -------------------------------------
say "ensuring tmux + deploying remote scripts ..."
bash "$DIR/rsh" "command -v tmux >/dev/null || (sudo apt-get update -qq >/dev/null 2>&1; sudo apt-get install -y -qq tmux >/dev/null 2>&1); tmux -V" 2>/dev/null
bash "$DIR/deploy.sh"

# 8. agy auth check ----------------------------------------------------------
if bash "$DIR/rsh" "ls ~/.gemini/antigravity-cli/antigravity-oauth-token >/dev/null 2>&1 && echo yes" 2>/dev/null | grep -q yes; then
  say "agy appears authenticated on this workstation ✅"
else
  echo
  echo "⚠️  agy is NOT authenticated on this workstation."
  echo "    HUMAN STEP (once): open a shell to the workstation and run 'agy', complete the OAuth, then exit:"
  echo "    gcloud workstations ssh --project=$PROJECT --cluster=$WS_CLUSTER --config=$WS_CONFIG --region=$WS_REGION $WS_NAME"
fi

echo
echo "Next:"
echo "  $DIR/rsh \"bash ~/agystart.sh\"                 # start the persistent agy session"
echo "  nohup $DIR/mirror.sh >/dev/null 2>&1 &          # transcript -> /tmp/agy-local.log"
echo "  nohup $DIR/live.sh   >/dev/null 2>&1 &          # live pane  -> /tmp/agy-live.txt"
