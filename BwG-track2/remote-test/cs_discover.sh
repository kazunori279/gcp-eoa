#!/bin/bash
# cs_discover.sh — shared Cloud Shell connection-discovery helper.
# Sourced by setshell.sh and shell_keeper.sh so the (fragile) parse of
# `gcloud cloud-shell ssh --dry-run` lives in exactly one place.
#
# Cloud Shell has a PUBLIC ssh endpoint, but its host IP + port are EPHEMERAL — they change
# whenever the VM restarts (idle timeout, etc.). `--dry-run` prints the exact ssh command
# gcloud would run; we parse out the key (-i), port (-p) and user@host from it and write
# CS_HOST / CS_PORT / CS_USER back into config.sh.
#
# Provides: cs_discover  — (re)discovers and rewrites config.sh. Returns 0 on success.
# Assumes config.sh is already sourced (for CS_PROJECT / CLOUDSDK_CONFIG) by the caller.

# _cs_dryrun_line: print the raw `gcloud cloud-shell ssh --dry-run` output.
_cs_dryrun_line(){
  gcloud cloud-shell ssh --project="$CS_PROJECT" --dry-run 2>/dev/null
}

# _cs_parse: read a dry-run ssh command on stdin, emit "HOST<TAB>PORT<TAB>USER" (empty on fail).
# Defensive: handles a plain space-joined command OR a python-list repr, and extracts by
# pattern (not fixed position) so extra -o flags don't shift anything.
# (The raw text is passed via env var CS_RAW, NOT python's stdin — python's stdin is taken
#  by the -c mechanism here / would collide with a heredoc.)
_cs_parse(){
  CS_RAW="$(cat)" python3 -c '
import re, os
raw = os.environ.get("CS_RAW", "")
# Unified tokenizer: split on whitespace, then strip list/quote punctuation from each token.
# Handles BOTH a space-joined command (…kazunori279@34.x.x.x … -- … \x27bash -l\x27)
# and a python-list repr ([\x27/usr/bin/ssh\x27, \x27-p\x27, \x27600 0\x27, …]).
toks = [t.strip("[],\x27\"") for t in raw.split()]
host = port = user = ""
i = 0
while i < len(toks):
    t = toks[i]
    if t == "-p" and i + 1 < len(toks):
        port = toks[i + 1].strip("[],\x27\""); i += 2; continue
    m = re.match(r"^([^@\s]+)@([A-Za-z0-9._-]+)$", t)  # user@host (host = IP or name)
    if m:
        user, host = m.group(1), m.group(2)
    i += 1
if host and port and user:
    print(f"{host}\t{port}\t{user}")
'
}

# cs_discover: discover coords and rewrite config.sh. Returns 0 on success, 1 on failure.
cs_discover(){
  local DIR CFG parsed host port user
  DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  CFG="$DIR/config.sh"
  parsed="$(_cs_dryrun_line | _cs_parse)"
  host="$(printf '%s' "$parsed" | cut -f1)"
  port="$(printf '%s' "$parsed" | cut -f2)"
  user="$(printf '%s' "$parsed" | cut -f3)"
  if [ -z "$host" ] || [ -z "$port" ] || [ -z "$user" ]; then
    echo "[cs_discover] could not parse Cloud Shell coords from --dry-run" >&2
    return 1
  fi
  sed -i.bak \
    -e "s|^export CS_HOST=.*|export CS_HOST=\"$host\"|" \
    -e "s|^export CS_PORT=.*|export CS_PORT=\"$port\"|" \
    -e "s|^export CS_USER=.*|export CS_USER=\"$user\"|" \
    "$CFG" && rm -f "$CFG.bak"
  # reflect into the current shell too (so a caller that already sourced config.sh sees them)
  export CS_HOST="$host" CS_PORT="$port" CS_USER="$user"
  export RSH_HOST="$host" RSH_PORT="$port" RSH_USER="$user"
  echo "[cs_discover] Cloud Shell at $user@$host:$port"
  return 0
}
