#!/bin/bash
# setshell.sh — point the remote-test harness at a Cloud Shell in ONE command.
#
# usage:  ./setshell.sh [project-id] [account@example.com]
#         (defaults to CS_PROJECT from config.sh; account is optional)
#
# It: sets the gcloud account+project, starts+authorizes the Cloud Shell (auto-starting the
# VM and provisioning ~/.ssh/google_compute_engine), discovers its ephemeral SSH coords,
# flips TARGET to 'cloudshell' in config.sh, (re)starts the connection keeper, verifies the
# channel, installs tmux + deploys the remote scripts, and checks agy auth.
#
# The one thing this can't do: the one-time `agy` OAuth. Do that once in a Cloud Shell you
# open from the Console (its ~/.gemini lives under the persistent $HOME, so it survives VM
# restarts). This script tells you if it's still missing.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Pick up CLOUDSDK_CONFIG (isolated gcloud profile, if set) so gcloud calls hit the intended
# profile. Also pulls in CS_PROJECT and cs_discover().
source "$DIR/config.sh"
source "$DIR/cs_discover.sh"

PROJECT="${1:-$CS_PROJECT}"
ACCOUNT="${2:-}"
CFG="$DIR/config.sh"
say(){ echo "[setshell] $*"; }

[ -n "$PROJECT" ] && [ "$PROJECT" != "your-gcp-project" ] \
  || { echo "ERROR: set CS_PROJECT in config.sh or pass a project-id: ./setshell.sh <project-id>"; exit 1; }

# 1. gcloud account + project ------------------------------------------------
if [ -n "$ACCOUNT" ]; then
  gcloud config set account "$ACCOUNT" >/dev/null 2>&1 \
    || { echo "ERROR: '$ACCOUNT' is not in 'gcloud auth list' — run: gcloud auth login"; exit 1; }
fi
gcloud config set project "$PROJECT" >/dev/null 2>&1 \
  || { echo "ERROR: cannot set project '$PROJECT'"; exit 1; }
say "account=$(gcloud config get-value account 2>/dev/null)  project=$PROJECT"

# persist the project into config.sh + point the resolver at cloudshell
sed -i.bak \
  -e "s|^export TARGET=.*|export TARGET=\"cloudshell\"|" \
  -e "s|^export CS_PROJECT=.*|export CS_PROJECT=\"$PROJECT\"|" \
  "$CFG" && rm -f "$CFG.bak"
export TARGET="cloudshell" CS_PROJECT="$PROJECT"

# 2. start + authorize + provision the SSH key -------------------------------
# `gcloud cloud-shell ssh` auto-starts the VM if stopped; --authorize-session pushes OAuth
# creds into the session and opens SSH access from this machine; it also creates the key.
say "starting + authorizing Cloud Shell (auto-starts the VM if stopped) ..."
gcloud cloud-shell ssh --project="$PROJECT" --authorize-session \
  --command="echo provisioned" >/dev/null 2>&1 \
  && say "Cloud Shell up + SSH key provisioned" \
  || say "WARN: authorize/provision had issues (check gcloud auth / Cloud Shell state)"

# 3. discover the ephemeral SSH coords -> config.sh --------------------------
say "discovering Cloud Shell SSH coords ..."
cs_discover || { echo "ERROR: could not discover Cloud Shell coords. Try: gcloud cloud-shell ssh --dry-run"; exit 1; }

# 4. (re)start the connection keeper -----------------------------------------
pkill -f 'shell_keeper.sh' 2>/dev/null
rm -f "$CS_SOCK"; sleep 1
nohup "$DIR/shell_keeper.sh" >/tmp/shell_keeper.log 2>&1 &
say "connection keeper restarted (pid $!) — waiting for it to come up ..."
sleep 5

# 5. verify the channel ------------------------------------------------------
if ! bash "$DIR/rsh" "echo OK" >/dev/null 2>&1; then
  sleep 6
  bash "$DIR/rsh" "echo OK" >/dev/null 2>&1 \
    || { echo "ERROR: channel not up. Check /tmp/shell_keeper.log, then retry ./rsh 'echo alive'"; exit 1; }
fi
say "✅ channel up on $(bash "$DIR/rsh" 'hostname' 2>/dev/null)"

# 6. remote prep: tmux + deploy scripts --------------------------------------
say "ensuring tmux + deploying remote scripts ..."
bash "$DIR/rsh" "command -v tmux >/dev/null || (sudo apt-get update -qq >/dev/null 2>&1; sudo apt-get install -y -qq tmux >/dev/null 2>&1); tmux -V" 2>/dev/null
bash "$DIR/deploy.sh"

# 7. agy auth check ----------------------------------------------------------
if bash "$DIR/rsh" "ls ~/.gemini/antigravity-cli/antigravity-oauth-token >/dev/null 2>&1 && echo yes" 2>/dev/null | grep -q yes; then
  say "agy appears authenticated on this Cloud Shell ✅"
else
  echo
  echo "⚠️  agy is NOT authenticated on this Cloud Shell."
  echo "    HUMAN STEP (once): open Cloud Shell from the Console (project $PROJECT), run 'agy',"
  echo "    complete the OAuth, then exit. ~/.gemini persists in \$HOME across VM restarts."
fi

echo
echo "Next:"
echo "  $DIR/rsh \"bash ~/agystart.sh\"                 # start the persistent agy session"
echo "  nohup $DIR/mirror.sh >/dev/null 2>&1 &          # transcript -> /tmp/agy-local.log"
echo "  nohup $DIR/live.sh   >/dev/null 2>&1 &          # live pane  -> /tmp/agy-live.txt"
