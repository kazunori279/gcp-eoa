# remote-test configuration — EDIT THESE for your target.
# Sourced by all local-side scripts (rsh, tunnel_sup.sh, shell_keeper.sh, drive.sh, poll.sh,
# mirror.sh, live.sh, deploy.sh, setlab.sh, setshell.sh).
#
# Two targets are supported (see TARGET below):
#   cloudshell  — a Cloud Shell on ANY GCP project, reached over its public SSH endpoint
#                 (gcloud cloud-shell ssh). Set up with ./setshell.sh. This is the default.
#   workstation — a Cloud Workstation on Qwiklabs, reached over an IAP TCP tunnel.
#                 Set up with ./setlab.sh.
# The driving layer (rsh + tmux/agy) is identical for both; only the connection differs.

# --- Target selector ---
export TARGET="cloudshell"

# --- Isolated gcloud profile (optional) ---
# Point gcloud at a separate config dir so a lab's account/project/ADC stay isolated from
# your personal ~/.config/gcloud. This mattered for the SHARED Qwiklabs student account.
# For the DEFAULT cloudshell target on your OWN project, leave this UNSET so gcloud uses your
# normal ~/.config/gcloud (the account you `gcloud auth login`'d as). Uncomment it for the
# workstation/Qwiklabs target, or export CLOUDSDK_CONFIG per-shell before sourcing.
#   export CLOUDSDK_CONFIG="$HOME/.config/gcloud-qwiklabs"
#   gcloud auth login                       # the account that owns the target
#   gcloud auth application-default login    # isolated ADC (only if you run client libs locally)
# export CLOUDSDK_CONFIG="${CLOUDSDK_CONFIG:-$HOME/.config/gcloud-qwiklabs}"

# ============================================================================
# Target: cloudshell  (set up / refreshed by setshell.sh + shell_keeper.sh)
# ============================================================================
export CS_PROJECT="gcp-samples-ic0"
export CS_KEY="$HOME/.ssh/google_compute_engine"      # gcloud's default cloud-shell key (same file as WS)
export CS_SOCK="$HOME/.ssh/cm-cshell.sock"            # ssh ControlMaster socket for Cloud Shell
# Discovered by setshell.sh / shell_keeper.sh via `gcloud cloud-shell ssh --dry-run`
# (Cloud Shell's public IP + port are ephemeral and change when the VM restarts):
export CS_HOST=""
export CS_PORT=""
export CS_USER=""

# ============================================================================
# Target: workstation  (set up / refreshed by setlab.sh + tunnel_sup.sh)
# Workstation coordinates (from the Qwiklabs / Cloud Workstations console)
# ============================================================================
export WS_PROJECT="qwiklabs-gcp-04-ebb916b610fa"
export WS_CLUSTER="workstation-cluster"
export WS_CONFIG="workstation-config"
export WS_REGION="us-central1"
export WS_NAME="ws-student-02-c253a240c8cc-qwiklabs-net"

# --- Local tunnel + multiplexed SSH (workstation only) ---
export WS_LOCAL_PORT="2222"                          # local port the IAP tunnel listens on
export WS_SSH_KEY="$HOME/.ssh/google_compute_engine" # key gcloud generates on first `workstations ssh`
export WS_REMOTE_USER="user"                         # workstation login user
export WS_CTRL_SOCK="$HOME/.ssh/cm-agy.sock"         # ssh ControlMaster socket

# --- Remote paths (relative to remote $HOME) ---
export WS_SESSION_LOG="agy-session.log"              # transcript written by agysend.sh

# --- Local artifacts ---
export WS_LOCAL_MIRROR="/tmp/agy-local.log"          # local copy of the transcript (tail -f this)
export WS_PROMPTS_JSON="/tmp/agy-prompts/all.json"   # extracted workshop prompts (see extract_prompts.py)

# ============================================================================
# Resolver: map TARGET -> the generic RSH_* connection vars that rsh consumes.
# rsh (and the mirror/live/poll loops that call it) are target-agnostic; only these
# values differ between cloudshell and workstation.
# ============================================================================
case "$TARGET" in
  cloudshell)
    export RSH_HOST="$CS_HOST"
    export RSH_PORT="$CS_PORT"
    export RSH_USER="$CS_USER"
    export RSH_KEY="$CS_KEY"
    export RSH_SOCK="$CS_SOCK"
    ;;
  workstation)
    export RSH_HOST="localhost"
    export RSH_PORT="$WS_LOCAL_PORT"
    export RSH_USER="$WS_REMOTE_USER"
    export RSH_KEY="$WS_SSH_KEY"
    export RSH_SOCK="$WS_CTRL_SOCK"
    ;;
  *)
    echo "config.sh: unknown TARGET '$TARGET' (expected 'cloudshell' or 'workstation')" >&2
    ;;
esac
