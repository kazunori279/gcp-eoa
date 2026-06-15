#!/bin/bash
# deploy.sh — push the remote-side scripts (remote/*.sh) to the workstation $HOME.
# Run after the tunnel supervisor is up.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/config.sh"
for f in agystart.sh agysend.sh; do
  B=$(base64 < "$DIR/remote/$f" | tr -d '\n')
  "$DIR/rsh" "echo '$B'|base64 -d>~/$f && chmod +x ~/$f && echo installed:$f"
done
