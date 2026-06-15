# Reference solution — "Rush Hour" transit agent (fallback)

A completed, validated copy of the agent the workshop builds, for when AGY gets
stuck (quota exhausted, repeated errors, hallucination) and you still want to
finish — especially the deploy. Captured from a clean M0→M2 run.

## What's here
```
transit-assistant/
  pyproject.toml
  app/
    __init__.py
    agent.py                # 3 tools wired in + the 5-rule system instruction (M1)
    tools.py                # get_scheduled_departures / check_disruptions / compute_reroute
    agent_runtime_app.py    # the TESTED runtime wrapper (M2) — region-correct sessions/memory,
                            # memory fallback, per-request client, session_id normalization
  scripts/
    runtime_smoke.py        # local smoke test (M2 Step 4)
```
(`agent_runtime_app.py` and `scripts/runtime_smoke.py` are the same files served at
`BwG-track2/agent_runtime_app.py` and `BwG-track2/runtime_smoke.py`.)

## How to use it
You still need your own `data/` (downloaded in M0) and a scaffolded project. If AGY
can't produce working code:
1. Scaffold the project (M1 Step 1) and download data (M0 Step 4) as normal.
2. Copy these files over the generated ones:
   `app/agent.py`, `app/tools.py`, `app/agent_runtime_app.py`, `scripts/runtime_smoke.py`, `pyproject.toml`.
3. Copy `data/` into `app/` (so it ships in the bundle), `uv sync`, then run the
   smoke test and deploy (M2 Steps 4–5).

> The Python here is model-generated from a real run; treat it as a working
> reference, not hand-audited production code.
