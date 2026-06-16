# remote-test configuration — EDIT THESE for your lab/workstation.
# Sourced by all local-side scripts (rsh, tunnel_sup.sh, drive.sh, poll.sh, mirror.sh, deploy.sh).

# --- Isolated gcloud profile ---
# Point gcloud at a separate config dir so this lab's account, project, and ADC are
# fully isolated from your personal ~/.config/gcloud. Kept OUTSIDE the repo so creds
# never get committed. Override per-shell by exporting CLOUDSDK_CONFIG before sourcing.
# One-time setup in this profile:
#   export CLOUDSDK_CONFIG="$HOME/.config/gcloud-qwiklabs"
#   gcloud auth login                      # the student-NN-...@qwiklabs.net account
#   gcloud auth application-default login   # isolated ADC (only if you run client libs locally)
export CLOUDSDK_CONFIG="${CLOUDSDK_CONFIG:-$HOME/.config/gcloud-qwiklabs}"

# --- Workstation coordinates (from the Qwiklabs / Cloud Workstations console) ---
export WS_PROJECT="qwiklabs-gcp-04-95d0ebf317cc"
export WS_CLUSTER="workstation-cluster"
export WS_CONFIG="workstation-config"
export WS_REGION="us-central1"
export WS_NAME="ws-student-04-b709478b5617-qwiklabs-net"

# --- Local tunnel + multiplexed SSH ---
export WS_LOCAL_PORT="2222"                          # local port the IAP tunnel listens on
export WS_SSH_KEY="$HOME/.ssh/google_compute_engine" # key gcloud generates on first `workstations ssh`
export WS_REMOTE_USER="user"                         # workstation login user
export WS_CTRL_SOCK="$HOME/.ssh/cm-agy.sock"         # ssh ControlMaster socket

# --- Remote paths (relative to remote $HOME) ---
export WS_SESSION_LOG="agy-session.log"              # transcript written by agysend.sh

# --- Local artifacts ---
export WS_LOCAL_MIRROR="/tmp/agy-local.log"          # local copy of the transcript (tail -f this)
export WS_PROMPTS_JSON="/tmp/agy-prompts/all.json"   # extracted workshop prompts (see extract_prompts.py)
