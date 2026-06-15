#!/bin/bash
# tunnel_sup.sh — keep a persistent IAP TCP tunnel to the workstation's SSH port alive.
#
# Why a supervisor and not a plain `while gcloud ...; do`:
#   The Cloud Workstations IAP tunnel idle-times-out after ~2 minutes, and when it
#   dies gcloud sometimes KEEPS THE LOCAL PORT OPEN (dead) instead of exiting — so a
#   loop that only restarts on process-exit gets stuck. We instead actively health-check
#   by SSHing `true` every 12s (which doubles as keepalive traffic) and force-restart
#   the tunnel when the probe fails.
#
# Run it in the background:  nohup ./tunnel_sup.sh >/tmp/tunnel_sup.log 2>&1 &
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/config.sh"

launch(){
  pkill -f "start-tcp-tunnel.*$WS_LOCAL_PORT" 2>/dev/null; sleep 1
  nohup gcloud workstations start-tcp-tunnel \
    --project="$WS_PROJECT" --cluster="$WS_CLUSTER" \
    --config="$WS_CONFIG" --region="$WS_REGION" \
    "$WS_NAME" 22 --local-host-port="localhost:$WS_LOCAL_PORT" \
    >/tmp/tunnel_raw.log 2>&1 &
}

healthy(){
  ssh -p "$WS_LOCAL_PORT" -i "$WS_SSH_KEY" -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null -o ConnectTimeout=8 -o LogLevel=ERROR \
    "$WS_REMOTE_USER@localhost" true 2>/dev/null
}

launch; sleep 6
while true; do
  if ! healthy; then
    echo "[sup $(date +%T)] tunnel unhealthy -> restart"
    rm -f "$WS_CTRL_SOCK"   # drop the stale ControlMaster socket
    launch; sleep 6
  fi
  sleep 12
done
