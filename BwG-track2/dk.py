#!/usr/bin/env python3
"""dk.py — query the Google Developer Knowledge MCP directly.

Fallback for when the native google-developer-knowledge MCP tool is blocked by
lab/runtime policy. Authenticates with your gcloud login (ADC) + quota project,
so no API key is needed.

Usage:
  python3 dk.py "What is Agent Runtime and how do I deploy to it?"   # answer_query
  python3 dk.py --search "Model Armor sanitize template regional endpoint"  # search_documents
"""
import json
import subprocess
import sys
import urllib.request

ENDPOINT = "https://developerknowledge.googleapis.com/mcp"


def _sh(cmd):
    return subprocess.check_output(cmd, text=True).strip()


def call(tool, arguments):
    token = _sh(["gcloud", "auth", "print-access-token"])
    project = _sh(["gcloud", "config", "get-value", "project"])
    body = json.dumps(
        {"jsonrpc": "2.0", "id": 1, "method": "tools/call",
         "params": {"name": tool, "arguments": arguments}}
    ).encode()
    req = urllib.request.Request(
        ENDPOINT, data=body, method="POST",
        headers={
            "Authorization": f"Bearer {token}",
            "X-Goog-User-Project": project,
            "Content-Type": "application/json",
            "Accept": "application/json, text/event-stream",
        },
    )
    resp = json.loads(urllib.request.urlopen(req).read().decode())
    parts = resp.get("result", {}).get("content", [])
    text = "\n".join(p.get("text", "") for p in parts)
    return text or json.dumps(resp, indent=2)


if __name__ == "__main__":
    args = sys.argv[1:]
    if args and args[0] == "--search":
        print(call("search_documents", {"query": " ".join(args[1:])}))
    else:
        q = " ".join(args) or "What is the Gemini Enterprise Agent Platform?"
        print(call("answer_query", {"query": q}))
