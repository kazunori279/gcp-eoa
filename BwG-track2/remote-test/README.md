# remote-test — driving the `agy` (Antigravity) CLI on a remote box, headless

A small harness for **running the BwG-track2 workshop prompts through the real `agy` CLI
on a remote box**, capturing the agent's full *trajectory* (tool calls + reasoning +
output) for each step so the workshop content can be QA'd / trajectory-evaluated.

**Two targets are supported** (see [Targets](#targets)):
- **Cloud Shell** on **any GCP project** — reached over its public SSH endpoint
  (`gcloud cloud-shell ssh`). Set up with `./setshell.sh`. **This is the default** and the
  lightest way to run: no lab provisioning, works on your own project.
- **Cloud Workstation** on **Qwiklabs** — reached over an IAP TCP tunnel. Set up with
  `./setlab.sh`.

The driving layer (tmux + `agy`, and everything the `drive.sh`/`poll.sh`/`mirror.sh` loops
do) is **identical for both** — only the connection differs. The same harness is reusable
for any "drive an interactive coding-agent CLI on a remote box, non-interactively, and
watch it" task.

---

## Evaluation results & reports

**Latest run: 2026-06-17** — fresh Qwiklabs lab (`student-02-c253a240c8cc`, project
`qwiklabs-gcp-04-ebb916b610fa`), driven end-to-end through the real `agy` CLI
(Antigravity CLI, Gemini 3.5 Flash). **All six modules pass** — one clean deploy
(`reasoningEngines/3116103914047406080`, us-east1), the deployed agent serves correctly,
and the agent is published to Gemini Enterprise (`explore-ai`).

> This run was on the Cloud Workstation target. The harness now defaults to the **Cloud Shell**
> target (`./setshell.sh`) on any GCP project; the next run's table will note which target it used.

| Module | Result | Elapsed\* | What it covers (latest run) |
|---|---|---|---|
| **M0 · Setup** | ✅ | ~3 min | DK MCP install + overwrite from real 0-byte config · project pin · `plan.md` · `agents-cli setup` (7 skills) · data download. **AGY restart after Step 1 confirmed load-bearing on a fresh lab.** |
| **M1 · Build** | ✅ | ~7.5 min | scaffold + 3 tools + 5-rule instruction; **3/3 scenarios pass** — headless test caught & fixed a real `compute_reroute` priority-queue bug |
| **M2 · Scale** | ✅ | ~18 min | sessions + Memory Bank + code-exec; smoke test green pre-deploy → **one clean deploy**; **4/4 deployed scenarios**; Memory Bank persistence verified via API |
| **M3 · Govern** | ✅ | ~2 min | registry/identity verify (**SPIFFE** + honest not-least-privilege audit) + Model Armor blocks jailbreak/PII, passes benign |
| **M4 · Optimize** | ✅ | ~25 min† | 10/10 crisis sim (agent self-fixed a session-reuse bug) + graded eval **4/4 PASSED** (0.87/1.00/0.81/0.93, `gemini-2.5-flash` judge) |
| **M5 · Engage** | ✅ | ~2 min | published to Gemini Enterprise (`explore-ai`); `registration_results.md` written; registration confirmed headlessly via the discoveryengine API |
| **End-to-end** | **✅ all 6** | **~55 min** | one deploy total; deployed agent serves correctly and is published to GE |

\* Elapsed = agy working time per module (from the `agysend` `[done step=…]` markers). Server-side
deploys (~6–10 min) overlap reading, so wall-clock is close to this.
† M4's `agysend` markers fire **very** early (the sim + `adk eval` run as agy background tasks it
poll-waits on); ~25 min is the observed wall-clock incl. the agent's self-correction and re-runs.

**Per-module reports** — each has a per-step trajectory table, timings, what worked, and a
prioritized content-improvement plan with applied/validated updates:
- [`eval-report/m0.md`](eval-report/m0.md) — M0 · Setup
- [`eval-report/m1.md`](eval-report/m1.md) — M1 · Build
- [`eval-report/m2.md`](eval-report/m2.md) — M2 · Scale
- [`eval-report/m3.md`](eval-report/m3.md) — M3 · Govern
- [`eval-report/m4.md`](eval-report/m4.md) — M4 · Optimize
- [`eval-report/m5.md`](eval-report/m5.md) — M5 · Engage

> **Elapsed-time metric.** Each `agysend` run records `elapsed=Ns` in its `[done step=…]` marker
> (prompt submit → completion detection, incl. the ~stable-s tail). Extract per-module timings with
> `./rsh "grep -oE '\[done step=[^]]*\]' ~/agy-session.log"`. For long background steps (e.g. the M2
> deploy) the marker can fire early — cross-check ground truth (`deployment_metadata.json` timestamps).

A report is written/overwritten and pushed after each module (see the **Per-module loop** below).

---

## Using this WITH a coding agent (the intended workflow)

This harness is meant to be **operated by a coding agent** (Claude Code, etc.) on your
laptop, which drives the *remote* `agy` for you. The split of duties:

**You (human), once — the parts an agent can't do:**
1. `gcloud auth login` as the account that owns the target (for Cloud Shell: your own
   Google account; for a Qwiklabs workstation: the **student** account). Interactive browser.
2. **Authenticate `agy` itself** on the remote box (interactive browser, ~30s OAuth window —
   too fast for an agent to round-trip). For **Cloud Shell**: open Cloud Shell from the
   Console, run `agy`, complete the login, then exit — `~/.gemini` lives under the persistent
   `$HOME`, so it survives VM restarts. For a **workstation**: open a normal shell to it and
   do the same. *(See Setup below.)*
3. Make sure no other interactive `agy` session is left open (it blocks headless runs).

**Then hand it to your coding agent** — point it at this file:

> "Read `BwG-track2/remote-test/README.md`. I've already done `gcloud auth login` and the
> one-time `agy` OAuth on the target. Set `CS_PROJECT` in `config.sh` and run `./setshell.sh`
> (Cloud Shell), then drive the BwG-track2 workshop steps (m0…m5) one module at a time,
> following the **Per-module loop** below."

The agent then owns everything else: running `setshell.sh` (or `setlab.sh`), starting the
connection keeper, `deploy.sh`, `agystart.sh`, and looping `drive.sh` / `poll.sh` per step.
You watch live with `tail -f /tmp/agy-local.log` (after the agent starts `mirror.sh`) or a
read-only `tmux attach -t agy` on the box.

### Per-module loop (required)

Drive **one module at a time**. After finishing each module, the agent MUST:

1. **Write the eval report** to `BwG-track2/remote-test/eval-report/m<N>.md` — the per-step
   trajectory table, timings, what worked, and a prioritized plan to improve that module's
   content (`BwG-track2/m<N>.html`). On a re-run, overwrite the existing report.
2. **Push it immediately** — commit and push `eval-report/m<N>.md` as soon as it's written
   (don't wait for the next instruction to commit the report).
3. **Update this README's results table** — refresh that module's row in the
   **Evaluation results & reports** table (date/lab in the intro line, ✅/❌, elapsed, and a
   one-line "what it covers" reflecting *this* run's findings). Keep it current every run.
4. **Notify** the user (the cc-notify webhook — see the user's notify hook).
5. **Stop and wait** for the user's instruction. Do **not** auto-advance to the next module.

This keeps the human in the loop: between modules they review the report, edit the workshop
content, and decide whether to continue, re-run, or change course.

Why the human-first auth: both logins are interactive browser flows, and `agy`'s in
particular times out in ~30s — an agent calling tools can't reliably complete it. Once the
credentials are cached, every subsequent step is non-interactive and agent-drivable.

---

## TL;DR architecture

**Cloud Shell (default)** — direct public SSH, no tunnel:

```
   your laptop                                 Cloud Shell (any GCP project)
 ┌───────────────┐  direct public SSH        ┌─────────────────────────────┐
 │ shell_keeper  │══ user@<ephemeral-ip> ════│ sshd (public endpoint)      │
 │ (keepalive +  │   :port  (discovered by   │                             │
 │  re-discover) │    gcloud cloud-shell     │  tmux session "agy"         │
 │   rsh ────────┼──── ssh --dry-run) ──────►│   └─ agy (interactive TUI)  │
 │ drive.sh      │   multiplexed ssh         │        = ONE conversation   │
 │ poll.sh       │   (ControlMaster)         │                             │
 │ mirror.sh ◄───┼──── tail -F ──────────────│  ~/agy-session.log          │
 └───────────────┘                           │  ~/agysend.sh ~/agystart.sh │
   tail -f /tmp/agy-local.log                └─────────────────────────────┘
```

**Cloud Workstation (Qwiklabs)** — same driving layer, reached through an IAP tunnel:

```
   your laptop                              Cloud Workstation
 ┌──────────────┐   gcloud IAP tunnel     ┌─────────────────────────────┐
 │ tunnel_sup.sh│════ localhost:2222 ═════│ sshd                        │
 │  (keepalive  │                         │                             │
 │   + restart) │   multiplexed ssh       │  tmux session "agy"         │
 │   rsh ───────┼──── (ControlMaster) ───►│   └─ agy (interactive TUI)  │
 └──────────────┘                         └─────────────────────────────┘
```

Two independent concerns, solved by two independent mechanisms:

| Concern | Solution | Why |
|---|---|---|
| Per-command SSH latency | **SSH ControlMaster** over the target's endpoint (`rsh`); a keeper holds it warm — `shell_keeper.sh` (Cloud Shell, direct) or `tunnel_sup.sh` (workstation, IAP tunnel) | a fresh `gcloud ... ssh` is ~10–15s; multiplexed reuse is ~0.3s |
| Keeping the agent alive + a single conversation | **`agy` interactive inside `tmux`** (`agystart.sh`) | `agy` is a TUI (needs a PTY); tmux also survives SSH drops so the conversation isn't lost |

### Targets

`config.sh` has a `TARGET` switch — `cloudshell` (default) or `workstation`. It resolves a
single set of generic connection vars (`RSH_HOST`/`RSH_PORT`/`RSH_USER`/`RSH_KEY`/`RSH_SOCK`)
that `rsh` consumes, so `rsh` and everything above it are **target-agnostic**. You normally
don't set `TARGET` by hand: `./setshell.sh` flips it to `cloudshell` and `./setlab.sh` uses
`workstation`. Cloud Shell's public IP + port are **ephemeral** (they change on VM restart),
so they're discovered via `gcloud cloud-shell ssh --dry-run` (see `cs_discover.sh`) and
re-discovered by `shell_keeper.sh` whenever the connection drops.

---

## The hard-won learnings

### Authentication is TWO separate logins
1. **gcloud** must be the Qwiklabs **student** account (`gcloud auth login`), or
   `workstations.*` calls 403. The student email looks like `student-NN-...@qwiklabs.net`.
   Run it under an **isolated `CLOUDSDK_CONFIG`** (config.sh sets one, default
   `~/.config/gcloud-qwiklabs`) so the lab account, project, and ADC stay separate from
   your personal `~/.config/gcloud` — switching labs or accounts never clobbers your
   day-to-day gcloud. All harness scripts source `config.sh`, so they inherit it
   automatically; for ad-hoc `gcloud`/`./rsh` calls, run them from a shell where you've
   sourced `config.sh` (or exported the same `CLOUDSDK_CONFIG`).
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

### Reading the trajectory — capture the frame, don't diff scrollback
- In the TUI pane, tool calls render as `● Bash(pwd)`, `● Create(/home/user/plan.md)`,
  `● google-developer-knowledge/answer_query(...)`; reasoning as `▸ Thought for 3s, 393 tokens`.
- **agy repaints in place** on the *normal* buffer (no alternate screen). It only spills into
  tmux scrollback when a step's output exceeds the pane height — and that scroll-during-
  streaming interleaves partial spinner frames into history, so a scrollback diff
  (`capture-pane -pS -32000` sliced by line-count growth) yields a garbled, duplicated
  transcript, and captures **nothing** for a short step that fits the viewport (no scroll →
  no history growth). Two fixes, both in `agystart.sh`/`agysend.sh`:
  1. **Tall pane** (`AGY_ROWS`, default 1000): a step almost never scrolls, so it renders as
     ONE clean final frame.
  2. **Frame capture + prompt-echo anchor**: at completion grab the current frame
     (`capture-pane -p`), strip ANSI + the trailing input-box/status chrome, and slice from
     the echoed `> <prompt>` line to the end. Falls back to full scrollback only if the step
     was long enough to scroll off the top of even the tall pane.
- `agy --log-file X` is a **diagnostic server log** (model label, MCP load errors,
  conversation IDs) — useful for debugging, **not** a clean trajectory.
- Full conversations are stored as protobuf at
  `~/.gemini/antigravity-cli/conversations/*.pb` (not easily parsed; the pane is better).
- Tool *output* is collapsed by agy (`(ctrl+o to expand)`); the captured trajectory shows the
  tool call + result summary as rendered, same as a human sees.

### Injecting multi-line prompts into a TUI
- `tmux send-keys "text" Enter` **submits on every embedded newline**. Instead:
  `tmux set-buffer` + `tmux paste-buffer -p` (the `-p` = **bracketed paste**, so agy
  treats the whole blob as one multi-line input), then a single `tmux send-keys Enter`.

### Detecting completion
- Poll `capture-pane`; when the rendered screen is **unchanged for N seconds**, agy is
  done (idle = empty `>` line + `? for shortcuts` status bar). The streaming output and
  spinner keep the screen changing while it works, so this is reliable. Use a generous
  stable window (15s+) and a per-step max for long ops (deploys).

### Cloud Shell: public SSH, but ephemeral + idle-stopped — supervise it too
- Cloud Shell has a **public SSH endpoint**, so there's **no IAP tunnel** for that target.
  Reach it directly with `gcloud cloud-shell ssh` (auto-starts the VM if stopped;
  `--authorize-session` pushes your OAuth creds in and opens SSH access from this machine).
- Its public **IP + port are ephemeral** — they change on VM restart. `--dry-run` prints the
  exact ssh command gcloud would run; `cs_discover.sh` parses host/port/user from it into
  `config.sh`. `shell_keeper.sh` health-checks (`ssh true`, doubling as idle keepalive) and,
  on failure, **re-authorizes + re-discovers** (restarts a stopped VM, re-opens the SSH ACL,
  rewrites the coords).
- `$HOME` (5 GB) **persists** across sessions, so the `agy` OAuth (`~/.gemini/...`) and your
  project files survive an idle-stop; anything installed **outside** `$HOME` (apt packages)
  does not.

### The IAP tunnel is flaky — supervise it (workstation target)
- `gcloud workstations start-tcp-tunnel` **idle-times-out (~2 min)**, and on death it
  sometimes **keeps the local port open while dead** — so a restart-on-exit loop hangs.
  `tunnel_sup.sh` instead **health-checks by SSHing `true` every 12s** (doubles as
  keepalive) and force-restarts on failure. `rsh` also sets `ServerAliveInterval=15` and
  does one auto-retry.
- Run each step's `agysend.sh` **detached (`nohup`) on the remote** (drive.sh does this),
  so a connection drop never interrupts a running step — it keeps going inside tmux; you just
  reconnect and read `~/agy-session.log`. (Same benefit on Cloud Shell.)

### Misc
- `tmux` on the workstation is **not preinstalled**; install with `sudo apt-get install -y
  tmux` (passwordless sudo is available in the lab). Cloud Shell usually has `tmux`
  preinstalled, but note apt installs there don't persist outside `$HOME` across VM restarts.
  `setshell.sh`/`setlab.sh` both run the install-if-missing guard.
- gcloud generates `~/.ssh/google_compute_engine` on the first `workstations ssh` /
  `cloud-shell ssh`; both `rsh` (direct or tunneled) and the keepers reuse that same key.

---

## Files

| File | Runs on | Purpose |
|---|---|---|
| `config.sh` | local | **edit this**: `TARGET` switch, Cloud Shell (`CS_*`) + workstation (`WS_*`) coordinates, paths, and optional `CLOUDSDK_CONFIG`. Resolves the generic `RSH_*` vars. Sourced by all local scripts. |
| `rsh` | local | run a command on the remote over the multiplexed SSH (~0.3s). Target-agnostic (consumes `RSH_*`). |
| `setshell.sh` | local | **Cloud Shell:** point the harness at a Cloud Shell in one command (set project → start+authorize → discover coords → `TARGET=cloudshell` → keeper → tmux/deploy → agy-auth check). |
| `shell_keeper.sh` | local | **Cloud Shell:** keep the direct SSH warm; re-authorize + re-discover ephemeral coords on drop. |
| `cs_discover.sh` | local | **Cloud Shell:** shared helper — parse `gcloud cloud-shell ssh --dry-run` → rewrite `CS_HOST/PORT/USER` in `config.sh`. |
| `setlab.sh` | local | **Workstation:** point the harness at a new Qwiklabs lab in one command (discover workstation → rewrite `config.sh` → provision key → tunnel → tmux/deploy → agy-auth check). |
| `tunnel_sup.sh` | local | **Workstation:** persistent self-healing IAP tunnel (`localhost:2222` → workstation:22). |
| `mirror.sh` | local | stream the per-step transcript to `/tmp/agy-local.log` for `tail -f`. |
| `live.sh` | local | snapshot the live agy pane to `/tmp/agy-live.txt` (`watch -n 1 cat …`) — live tool calls/streaming. |
| `extract_prompts.py` | local | parse `BwG-track2/m*.html` → `all.json` (prompt blocks by id). |
| `drive.sh` | local | send one workshop step (`<module> <blockid> <step>`) to agy, detached. |
| `poll.sh` | local | one-shot status: live pane + done/running. |
| `deploy.sh` | local | push `remote/*.sh` to the remote `$HOME`. |
| `remote/agystart.sh` | remote | (re)start the persistent `agy` tmux session. |
| `remote/agysend.sh` | remote | paste a prompt, wait for completion, log the trajectory. |
| `eval-report/m*.md` | output | per-module trajectory evaluation + content-improvement plan. |

---

## Setup — Cloud Shell (default, one time)

The lightest path: your own GCP project, no lab to provision. `setshell.sh` does the
connection setup in one command; you only do the two interactive logins.

```bash
cd remote-test
$EDITOR config.sh                       # set CS_PROJECT="<your-gcp-project>"
                                        # (CLOUDSDK_CONFIG is optional for your own project —
                                        #  comment it out to use your normal gcloud config)

# 1. authenticate agy ONCE, interactively (human) — open Cloud Shell from the Console:
#    https://console.cloud.google.com  → select your project → "Activate Cloud Shell" →
#    run `agy`, complete the OAuth, then exit. ~/.gemini persists in $HOME across restarts.

# 2. gcloud as the account that owns the project (interactive), then one command:
gcloud auth login                       # your Google account
./setshell.sh                           # start+authorize Cloud Shell → discover coords →
                                        # TARGET=cloudshell → keeper → tmux/deploy → agy check
#   (or: ./setshell.sh <project-id> [account@example.com] to override config.sh)

# 3. extract the workshop prompts
python3 extract_prompts.py .. /tmp/agy-prompts/all.json   # parent dir = BwG-track2 (the module HTML)

# 4. start the persistent agy session + (optional) mirror the transcript locally
./rsh "bash ~/agystart.sh"
nohup ./mirror.sh >/dev/null 2>&1 &
tail -f /tmp/agy-local.log
```

`setshell.sh` starts the Cloud Shell VM if it's stopped and re-opens SSH access, so you can
re-run it any time to reconnect. Everything after it (`drive.sh`/`poll.sh`/…) is identical to
the workstation flow.

## Setup — Cloud Workstation / Qwiklabs (one time)

```bash
cd remote-test
$EDITOR config.sh                       # set TARGET="workstation" + WS_PROJECT / WS_CLUSTER / WS_CONFIG / WS_REGION / WS_NAME

# 1. gcloud as the STUDENT account (interactive) — in an ISOLATED profile so the
#    lab account/project/ADC never touch your personal ~/.config/gcloud.
#    config.sh exports CLOUDSDK_CONFIG (default ~/.config/gcloud-qwiklabs);
#    source it (or export the same var) before the login so it lands in that profile:
source config.sh                        # sets CLOUDSDK_CONFIG (isolated gcloud dir)
gcloud auth login                       # pick student-NN-...@qwiklabs.net
gcloud auth application-default login    # only if you run client libs locally (isolated ADC)

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

> **Tip:** `./setlab.sh <project-id> [student@qwiklabs.net]` automates steps 3–4 (+ tmux,
> deploy, agy-auth check) for the workstation target — see [Switching labs](#switching-labs-new-qwiklabs-account--project).

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
#    keeper: Cloud Shell -> ./shell_keeper.sh ;  workstation -> ./tunnel_sup.sh  (only if not already running)
nohup ./shell_keeper.sh >/tmp/shell_keeper.log 2>&1 &   # (workstation: nohup ./tunnel_sup.sh >/tmp/tunnel_sup.log 2>&1 &)
./rsh "bash ~/agystart.sh"
nohup ./mirror.sh >/dev/null 2>&1 &
nohup ./live.sh   >/dev/null 2>&1 &
```

> **Cloud Shell note:** step 4's "lab only" DK-MCP reset applies to the workshop's fresh-lab
> state — run it the same way on Cloud Shell to genuinely exercise M0 Step 1's overwrite. All
> `./rsh` commands above are target-agnostic.

## Switching labs (new Qwiklabs account / project)

Qwiklabs labs are time-boxed — when one expires, the student account is deleted and the
workstation is gone. To repoint at a fresh lab, do the two human logins, then one command:

```bash
source config.sh                        # isolated CLOUDSDK_CONFIG (lab profile)
gcloud auth login                       # the NEW student-NN-...@qwiklabs.net (interactive)
./setlab.sh <new-project-id> [student-NN-...@qwiklabs.net]
```

`setlab.sh` sources `config.sh` itself, so its gcloud calls already run in the isolated
profile; the `source` above is only so your own `gcloud auth login` lands in the same dir.

`setlab.sh` sets the gcloud account+project, **auto-discovers** the workstation
(`gcloud workstations list` → `config.sh`), provisions the SSH key, restarts the tunnel
supervisor, installs `tmux`, deploys the remote scripts, and tells you whether `agy` still
needs its one-time OAuth. Then start the session + watchers as it prints.

> Everything lab-specific lives in `config.sh`; `setlab.sh` is just the automated way to
> rewrite it. You can still edit `config.sh` by hand for non-Qwiklabs targets.

## Reconnecting a Cloud Shell (new project, or after an idle-stop)

Cloud Shell coords are ephemeral, but reconnecting is the same one command — it restarts a
stopped VM, re-opens SSH access, and re-discovers the coords:

```bash
gcloud auth login                       # only if the account changed
./setshell.sh [new-project-id]          # defaults to CS_PROJECT in config.sh
```

`shell_keeper.sh` also re-discovers automatically mid-run if the connection drops, so you
usually don't need to re-run `setshell.sh` unless you're switching projects.

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
   detach with `Ctrl-b d`). Target-agnostic — it reuses the resolved `RSH_*` coords:
   ```bash
   source config.sh
   ssh -p "$RSH_PORT" -i "$RSH_KEY" -o StrictHostKeyChecking=no \
     -o UserKnownHostsFile=/dev/null -t "$RSH_USER@$RSH_HOST" "tmux attach -t agy -r"
   ```
   (On Cloud Shell you can also just `gcloud cloud-shell ssh --command="tmux attach -t agy -r"`.)

> If you read-only attach, the session size is pinned (`window-size manual`) in
> `agystart.sh` so the attach can't reflow the pane `agysend` captures. **Caveat:** old tmux
> (e.g. Cloud Shell's 2.1) doesn't support `window-size`/`resize-window` — the tall `-y` at
> creation still holds while detached, but **attaching from a smaller terminal can reflow the
> pane** and disturb capture. Prefer `live.sh` (which only `capture-pane`s, never attaches).

## Transcript / artifacts
- `~/agy-session.log` on the remote (mirrored to `/tmp/agy-local.log`): every
  prompt + the new pane content (trajectory) + a `[done step=... elapsed=Ns]` marker.
- The agent's project files land in the remote `$HOME` (e.g. `~/plan.md`,
  `~/data/`, `~/transit-assistant/`). On Cloud Shell this `$HOME` is the 5 GB persistent disk.

## Troubleshooting
- `rsh` hangs / empty output → connection dropped. **Cloud Shell:** `tail /tmp/shell_keeper.log`;
  the keeper re-authorizes + re-discovers within a ~30s cycle — retry, or re-run `./setshell.sh`.
  **Workstation:** `tail /tmp/tunnel_sup.log` and `/tmp/tunnel_raw.log`; the supervisor restarts
  within ~12–18s; retry.
- Cloud Shell coords look stale after a restart → the keeper rewrites `CS_HOST/PORT/USER` in
  `config.sh`; confirm with `grep '^export CS_' config.sh`, or force it with
  `source config.sh && source cs_discover.sh && cs_discover`.
- A step seems stuck → `./poll.sh <step>`; if the pane shows an idle `>` but no done
  marker, `agysend` is just finishing its stability wait. If agy is asking a question,
  it needs input you can send with `./rsh "tmux send-keys -t agy 'answer' Enter"`.
- agy "not logged in" in logs → redo the one-time agy OAuth interactively (for Cloud Shell,
  in a Console-opened Cloud Shell).
- Want a clean conversation → `./rsh "bash ~/agystart.sh"` restarts the session
  (continuity then relies on `plan.md` on disk, by workshop design).
