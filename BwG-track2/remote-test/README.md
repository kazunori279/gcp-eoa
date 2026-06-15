# remote-test — driving the `agy` (Antigravity) CLI on a Cloud Workstation, headless

A small harness for **running the BwG-track2 workshop prompts through the real `agy` CLI
on a remote Google Cloud Workstation**, capturing the agent's full *trajectory* (tool
calls + reasoning + output) for each step so the workshop content can be QA'd /
trajectory-evaluated.

The same harness is reusable for any "drive an interactive coding-agent CLI on a remote
box, non-interactively, and watch it" task.

---

## Using this WITH a coding agent (the intended workflow)

This harness is meant to be **operated by a coding agent** (Claude Code, etc.) on your
laptop, which drives the *remote* `agy` for you. The split of duties:

**You (human), once — the parts an agent can't do:**
1. `gcloud auth login` as the **Qwiklabs student** account (interactive browser).
2. **Authenticate `agy` itself** on the workstation (interactive browser, ~30s OAuth
   window — too fast for an agent to round-trip). Open a normal shell to the workstation,
   run `agy`, complete the login, then exit. *(See Setup step 5 below.)*
3. Make sure no other interactive `agy` session is left open (it blocks headless runs).

**Then hand it to your coding agent** — point it at this file:

> "Read `BwG-track2/remote-test/README.md`. I've already done `gcloud auth login` (student account)
> and the one-time `agy` OAuth on the workstation. Edit `config.sh` for my workstation,
> bring up the tunnel + persistent agy session, then drive the BwG-track2 workshop steps
> (m0…m5) one module at a time, following the **Per-module loop** below."

The agent then owns everything else: editing `config.sh`, starting `tunnel_sup.sh`,
`deploy.sh`, `agystart.sh`, and looping `drive.sh` / `poll.sh` per step. You watch live
with `tail -f /tmp/agy-local.log` (after the agent starts `mirror.sh`) or
`tmux attach -t agy` on the workstation.

### Per-module loop (required)

Drive **one module at a time**. After finishing each module, the agent MUST:

1. **Write the eval report** to `BwG-track2/remote-test/eval-report/m<N>.md` — the per-step
   trajectory table, timings, what worked, and a prioritized plan to improve that module's
   content (`BwG-track2/m<N>.html`). On a re-run, overwrite the existing report.
2. **Push it immediately** — commit and push `eval-report/m<N>.md` as soon as it's written
   (don't wait for the next instruction to commit the report).
3. **Notify** the user (the cc-notify webhook — see the user's notify hook).
4. **Stop and wait** for the user's instruction. Do **not** auto-advance to the next module.

This keeps the human in the loop: between modules they review the report, edit the workshop
content, and decide whether to continue, re-run, or change course.

Why the human-first auth: both logins are interactive browser flows, and `agy`'s in
particular times out in ~30s — an agent calling tools can't reliably complete it. Once the
credentials are cached, every subsequent step is non-interactive and agent-drivable.

---

## TL;DR architecture

```
   your laptop                              Cloud Workstation
 ┌──────────────┐   gcloud IAP tunnel     ┌─────────────────────────────┐
 │ tunnel_sup.sh│════ localhost:2222 ═════│ sshd                        │
 │  (keepalive  │                         │                             │
 │   + restart) │   multiplexed ssh       │  tmux session "agy"         │
 │   rsh ───────┼──── (ControlMaster) ───►│   └─ agy (interactive TUI)  │
 │ drive.sh     │                         │        = ONE conversation   │
 │ poll.sh      │                         │                             │
 │ mirror.sh ◄──┼──── tail -F ────────────│  ~/agy-session.log          │
 └──────────────┘                         │  ~/agysend.sh ~/agystart.sh │
   tail -f /tmp/agy-local.log             └─────────────────────────────┘
```

Two independent concerns, solved by two independent mechanisms:

| Concern | Solution | Why |
|---|---|---|
| Per-command SSH latency | **persistent IAP tunnel + SSH ControlMaster** (`tunnel_sup.sh` + `rsh`) | a fresh `gcloud workstations ssh` is ~10–15s; multiplexed reuse is ~0.3s |
| Keeping the agent alive + a single conversation | **`agy` interactive inside `tmux`** (`agystart.sh`) | `agy` is a TUI (needs a PTY); tmux also survives tunnel/SSH drops so the conversation isn't lost |

---

## The hard-won learnings

### Authentication is TWO separate logins
1. **gcloud** must be the Qwiklabs **student** account (`gcloud auth login`), or
   `workstations.*` calls 403. The student email looks like `student-NN-...@qwiklabs.net`.
2. **`agy` has its OWN Antigravity OAuth**, separate from gcloud. It must be done **once,
   interactively, by a human** on the workstation (`agy` prints a URL with a ~30s wait —
   too short to complete through slow tool round-trips). After that, `agy` silent-auths
   via the keyring (`ChainedAuth: authenticated via keyring (effective: gcp)`), so
   headless runs work. The login also detects the SSH session and uses file-based token
   storage.

### `agy` CLI modes
- `agy -p "..."` = **print mode** (one-shot, non-interactive). `-c` continues the most
  recent conversation. **Avoid for this harness**: every call cold-starts (~15–30s), and
  its stdout is block-buffered over SSH so you go blind until it exits.
- **Interactive TUI** (just `agy`) in tmux = **what we use**. One long-lived process =
  one conversation, no cold starts, and the pane shows the **trajectory**.
- Always pass **`--add-dir ~`** or agy operates on an internal *scratch* dir, not your
  project, and file edits land in the wrong place.
- **`--dangerously-skip-permissions`** is required for headless tool execution (otherwise
  it blocks on permission prompts). Throwaway-lab only.
- **Single-instance contention**: a human's interactive `agy` can block a headless one.
  Close other `agy` sessions before driving.

### Reading the trajectory
- In the TUI pane, tool calls render as `● Bash(pwd)`, `● Create(/home/user/plan.md)`,
  `● google-developer-knowledge/answer_query(...)`; reasoning as `▸ Thought for 3s, 393 tokens`.
  Capture with `tmux capture-pane -pS -32000` and strip ANSI. This is the cleanest
  trajectory source.
- `agy --log-file X` is a **diagnostic server log** (model label, MCP load errors,
  conversation IDs) — useful for debugging, **not** a clean trajectory.
- Full conversations are stored as protobuf at
  `~/.gemini/antigravity-cli/conversations/*.pb` (not easily parsed; the pane is better).

### Injecting multi-line prompts into a TUI
- `tmux send-keys "text" Enter` **submits on every embedded newline**. Instead:
  `tmux set-buffer` + `tmux paste-buffer -p` (the `-p` = **bracketed paste**, so agy
  treats the whole blob as one multi-line input), then a single `tmux send-keys Enter`.

### Detecting completion
- Poll `capture-pane`; when the rendered screen is **unchanged for N seconds**, agy is
  done (idle = empty `>` line + `? for shortcuts` status bar). The streaming output and
  spinner keep the screen changing while it works, so this is reliable. Use a generous
  stable window (15s+) and a per-step max for long ops (deploys).

### The IAP tunnel is flaky — supervise it
- `gcloud workstations start-tcp-tunnel` **idle-times-out (~2 min)**, and on death it
  sometimes **keeps the local port open while dead** — so a restart-on-exit loop hangs.
  `tunnel_sup.sh` instead **health-checks by SSHing `true` every 12s** (doubles as
  keepalive) and force-restarts on failure. `rsh` also sets `ServerAliveInterval=15` and
  does one auto-retry.
- Run each step's `agysend.sh` **detached (`nohup`) on the remote** (drive.sh does this),
  so a tunnel drop never interrupts a running step — it keeps going inside tmux; you just
  reconnect and read `~/agy-session.log`.

### Misc
- `tmux` is **not preinstalled** on the workstation; install with `sudo apt-get install -y
  tmux` (passwordless sudo is available in the lab).
- gcloud generates `~/.ssh/google_compute_engine` on the first `workstations ssh`; the
  manual tunnel + `rsh` reuse that key.

---

## Files

| File | Runs on | Purpose |
|---|---|---|
| `config.sh` | local | **edit this**: workstation coordinates, ports, paths. Sourced by all local scripts. |
| `tunnel_sup.sh` | local | persistent self-healing IAP tunnel (`localhost:2222` → workstation:22). |
| `rsh` | local | run a command on the workstation over the multiplexed SSH (~0.3s). |
| `mirror.sh` | local | stream the per-step transcript to `/tmp/agy-local.log` for `tail -f`. |
| `live.sh` | local | snapshot the live agy pane to `/tmp/agy-live.txt` (`watch -n 1 cat …`) — live tool calls/streaming. |
| `extract_prompts.py` | local | parse `BwG-track2/m*.html` → `all.json` (prompt blocks by id). |
| `drive.sh` | local | send one workshop step (`<module> <blockid> <step>`) to agy, detached. |
| `poll.sh` | local | one-shot status: live pane + done/running. |
| `deploy.sh` | local | push `remote/*.sh` to the workstation `$HOME`. |
| `setlab.sh` | local | **point the harness at a new lab in one command** (account/project → discover workstation → rewrite `config.sh` → provision key → tunnel → tmux/deploy → agy-auth check). |
| `remote/agystart.sh` | workstation | (re)start the persistent `agy` tmux session. |
| `remote/agysend.sh` | workstation | paste a prompt, wait for completion, log the trajectory. |
| `eval-report/m*.md` | output | per-module trajectory evaluation + content-improvement plan. |

---

## Setup (one time)

```bash
cd remote-test
$EDITOR config.sh                       # set WS_PROJECT / WS_CLUSTER / WS_CONFIG / WS_REGION / WS_NAME

# 1. gcloud as the STUDENT account (interactive)
gcloud auth login                       # pick student-NN-...@qwiklabs.net

# 2. extract the workshop prompts
python3 extract_prompts.py .. /tmp/agy-prompts/all.json   # parent dir = BwG-track2 (the module HTML)

# 3. start the tunnel supervisor (leave running)
nohup ./tunnel_sup.sh >/tmp/tunnel_sup.log 2>&1 &
sleep 8 && ./rsh "echo connected; hostname"

# 4. install tmux on the workstation (if missing) + push remote scripts
./rsh "command -v tmux || sudo apt-get install -y -qq tmux"
./deploy.sh

# 5. authenticate agy ONCE, interactively (human):
#    open a normal shell to the workstation and run `agy`, complete the OAuth, then exit.
gcloud workstations ssh --project=$WS_PROJECT --cluster=$WS_CLUSTER \
  --config=$WS_CONFIG --region=$WS_REGION $WS_NAME    # then run: agy   (login, then Ctrl-C/exit)

# 6. start the persistent agy session
./rsh "bash ~/agystart.sh"

# 7. (optional) mirror the transcript locally and watch it
nohup ./mirror.sh >/dev/null 2>&1 &
tail -f /tmp/agy-local.log
```

## Preflight — reset to a clean state (before a from-scratch re-run)

Run this between test runs (and after editing any module HTML) so the next run starts truly
fresh and actually exercises the current content. **Keep the agy auth** (`antigravity-oauth-token`) —
do NOT delete it, or you'll need the interactive login again.

```bash
# 0. RE-EXTRACT prompts — REQUIRED after editing any m*.html (the driver reads all.json)
python3 extract_prompts.py .. /tmp/agy-prompts/all.json

# 1. stop the agy session + any stray mirror tails
./rsh "tmux kill-session -t agy 2>/dev/null; pkill -f 'tail -.*agy-session.log' 2>/dev/null; true"

# 2. (DESTRUCTIVE, cloud) delete the deployed Agent Runtime engine, if one exists.
#    Get PROJECT_NUMBER / REGION / ENGINE_ID from a prior deployment_metadata.json or the console.
./rsh 'ENG=projects/PROJECT_NUMBER/locations/REGION/reasoningEngines/ENGINE_ID; \
  curl -s -X DELETE -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  "https://REGION-aiplatform.googleapis.com/v1/${ENG}?force=true"'

# 3. wipe project + plan + harness logs + agy conversation history
./rsh 'rm -rf ~/transit-* ~/plan.md ~/data ~/agy-session.log ~/.aylogs/* \
  ~/.gemini/antigravity-cli/conversations/* ~/.gemini/antigravity-cli/brain/*'

# 4. (lab only) reset the DK MCP config to the FRESH-LAB state, so M0 Step 1's overwrite
#    logic is genuinely exercised: empty mcp_config.json + no allow rule (keep other keys).
./rsh ': > ~/.gemini/config/mcp_config.json; : > ~/.gemini/antigravity-cli/mcp_config.json; \
  python3 -c "import json,os; p=os.path.expanduser(chr(126)+\"/.gemini/antigravity-cli/settings.json\"); \
  d=json.load(open(p)); d.pop(\"permissions\",None); json.dump(d,open(p,\"w\"),indent=2)"'

# 5. verify clean (expect: no agy procs; no transit-*/plan.md; mcp_config 0 bytes; permissions count 0; engine 404)
./rsh 'pgrep -af agy|grep -v pgrep||echo "no agy"; ls -ld ~/transit-* ~/plan.md 2>&1; \
  wc -c ~/.gemini/config/mcp_config.json; grep -c permissions ~/.gemini/antigravity-cli/settings.json'

# 6. restart watchers + a fresh agy session
nohup ./tunnel_sup.sh >/tmp/tunnel_sup.log 2>&1 &   # only if not already running
./rsh "bash ~/agystart.sh"
nohup ./mirror.sh >/dev/null 2>&1 &
nohup ./live.sh   >/dev/null 2>&1 &
```

## Switching labs (new Qwiklabs account / project)

Qwiklabs labs are time-boxed — when one expires, the student account is deleted and the
workstation is gone. To repoint at a fresh lab, do the two human logins, then one command:

```bash
gcloud auth login                       # the NEW student-NN-...@qwiklabs.net (interactive)
./setlab.sh <new-project-id> [student-NN-...@qwiklabs.net]
```

`setlab.sh` sets the gcloud account+project, **auto-discovers** the workstation
(`gcloud workstations list` → `config.sh`), provisions the SSH key, restarts the tunnel
supervisor, installs `tmux`, deploys the remote scripts, and tells you whether `agy` still
needs its one-time OAuth. Then start the session + watchers as it prints.

> Everything lab-specific lives in `config.sh`; `setlab.sh` is just the automated way to
> rewrite it. You can still edit `config.sh` by hand for non-Qwiklabs targets.

## Driving the workshop

```bash
# send a step:  drive.sh <module> <blockid> <stepname> [max_s] [stable_s]
./drive.sh m0 ctx-combined   m0s2  360 15     # brief + create plan.md
./poll.sh  m0s2                                # check status (or watch the local mirror)

./drive.sh m0 cmd-agents-setup  m0s3 300 12    # uvx google-agents-cli setup
./drive.sh m0 cmd-download-data m0s4 240 12    # download GTFS + disruptions
# ... m1 step1-instr m1s1, etc.
```

Block ids per module come from `extract_prompts.py` output (e.g. `m0: ctx-dk-mcp,
cmd-dk-tryit, ctx-dk-helper, ctx-combined, cmd-agents-setup, cmd-download-data, ...`).

**Important:** only run one `drive.sh` at a time — wait for the previous step's
`[done step=...]` marker (poll.sh / mirror) before sending the next, or two `agysend`
pastes collide in the same TUI.

## Watching live

Three views, pick what you need:

1. **Live trajectory** (tool calls + streaming, ~2s fresh) — `live.sh` snapshots the pane:
   ```bash
   nohup ./live.sh >/dev/null 2>&1 &   # then:
   watch -n 1 cat /tmp/agy-live.txt
   ```
2. **Per-step transcript** (clean prompt → response) — `mirror.sh`:
   ```bash
   nohup ./mirror.sh >/dev/null 2>&1 &  # then:
   tail -f /tmp/agy-local.log
   ```
3. **True live TUI, read-only** (won't disturb the run; size is pinned; `-r` read-only,
   detach with `Ctrl-b d`):
   ```bash
   ssh -p 2222 -i ~/.ssh/google_compute_engine -o StrictHostKeyChecking=no \
     -o UserKnownHostsFile=/dev/null -t user@localhost "tmux attach -t agy -r"
   ```

> If you read-only attach, the session size is pinned (`window-size manual`) in
> `agystart.sh`/setup so the attach can't reflow the pane `agysend` captures.

## Evaluation reports

After each module is driven, the trajectory is evaluated and written to
`eval-report/m<N>.md` — a per-step table (prompt → tools used → outcome → verdict), a
**timings** table (elapsed wall-clock per step + module total, from the `agysend` done
markers), what worked, and a prioritized plan for improving that module's content
(`BwG-track2/m<N>.html`). The coding agent should append one report per module as it goes.

> **Elapsed-time metric.** Each `agysend` run records `elapsed=Ns` in its `[done step=…]`
> marker (wall-clock from prompt submit to completion detection, including the ~stable-s
> idle-confirmation tail). Extract per-module timings with:
> `./rsh "grep -oE '\[done step=[^]]*\]' ~/agy-session.log"`. For long background steps
> (e.g. M2 deploy) the marker can fire early — cross-check against ground truth
> (`deployment_metadata.json` timestamps).

- [`eval-report/m0.md`](eval-report/m0.md) — M0 · Setup (all 4 steps ✅)
- [`eval-report/m1.md`](eval-report/m1.md) — M1 · Build (all 4 steps ✅; agent validated on 3 scenarios)
- [`eval-report/m2.md`](eval-report/m2.md) — M2 · Scale (deploy/sessions/code-exec ✅; **deployed agent broken** — 3 stacked runtime bugs, `global`-location is the key one)
- [`eval-report/m3.md`](eval-report/m3.md) — M3 · Govern (Step 2 verify + Step 3 Model Armor ✅; identity-expectation caveat)
- [`eval-report/m4.md`](eval-report/m4.md) — M4 · Optimize (10-scenario sim + graded eval 4/4 ✅)
- [`eval-report/m5.md`](eval-report/m5.md) — M5 · Engage (published to Gemini Enterprise ✅; registration_results.md gap)

## Transcript / artifacts
- `~/agy-session.log` on the workstation (mirrored to `/tmp/agy-local.log`): every
  prompt + the new pane content (trajectory) + a `[done step=... elapsed=Ns]` marker.
- The agent's project files land in the workstation `$HOME` (e.g. `~/plan.md`,
  `~/data/`, `~/transit-assistant/`).

## Troubleshooting
- `rsh` hangs / empty output → tunnel dropped; check `tail /tmp/tunnel_sup.log` and
  `/tmp/tunnel_raw.log`. The supervisor restarts within ~12–18s; retry.
- A step seems stuck → `./poll.sh <step>`; if the pane shows an idle `>` but no done
  marker, `agysend` is just finishing its stability wait. If agy is asking a question,
  it needs input you can send with `./rsh "tmux send-keys -t agy 'answer' Enter"`.
- agy "not logged in" in logs → redo step 5 (agy OAuth) interactively.
- Want a clean conversation → `./rsh "bash ~/agystart.sh"` restarts the session
  (continuity then relies on `plan.md` on disk, by workshop design).
