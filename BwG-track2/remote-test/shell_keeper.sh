#!/bin/bash
# shell_keeper.sh — keep the Cloud Shell SSH connection warm and self-heal, without a tunnel.
#
# The Cloud Shell analog of tunnel_sup.sh. Cloud Shell has a PUBLIC ssh endpoint, so there's
# no IAP tunnel to babysit — but two things still need supervising:
#   1. Idle timeout: Cloud Shell stops after inactivity. A periodic `ssh true` doubles as
#      keepalive traffic to hold the session open during a long test run.
#   2. Ephemeral coords: when the VM restarts, its public IP + port CHANGE and the SSH ACL
#      for this machine may lapse. On a failed health-check we re-authorize (which also
#      restarts a stopped VM and re-opens SSH access from here) and re-discover the coords.
#
# Run it in the background:  nohup ./shell_keeper.sh >/tmp/shell_keeper.log 2>&1 &
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/config.sh"
source "$DIR/cs_discover.sh"

healthy(){
  ssh -p "$RSH_PORT" -i "$RSH_KEY" -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null -o ControlMaster=auto -o ControlPath="$RSH_SOCK" \
    -o ControlPersist=600 -o ConnectTimeout=8 -o LogLevel=ERROR \
    "$RSH_USER@$RSH_HOST" true 2>/dev/null
}

heal(){
  echo "[keeper $(date +%T)] unhealthy -> re-authorize + re-discover"
  rm -f "$RSH_SOCK"   # drop the stale ControlMaster socket
  # re-authorize: starts a stopped VM, re-opens SSH access from this machine, refreshes key
  gcloud cloud-shell ssh --project="$CS_PROJECT" --authorize-session \
    --command=true >/dev/null 2>&1
  cs_discover || echo "[keeper $(date +%T)] re-discover failed; will retry"
}

# ensure we have coords + an open channel on startup
healthy || heal
while true; do
  if ! healthy; then heal; fi
  sleep 30
done
