# Era of Agents — Hands-on Workshop Series

Workshop catalog and event history for the Google Cloud "Era of Agents" hands-on workshop program (2024–2026).

**[View the dashboard](https://kazunori279.github.io/gcp-eoa/eoa-workshops.html)**

## Contents

- **[eoa-workshops.html](eoa-workshops.html)** — Self-contained interactive dashboard with:
  - **Workshop Catalog** — 38 workshops across 4 pillars (Build, Scale, Optimize, Govern) with search and filtering
  - **Guidelines** — Instructions for workshop organizers, speakers, and content owners
  - **Past Events** — 35 events, 2,035+ total attendees across multiple countries

### Build with Gemini World Tour — Track 2: Rush Hour

2-hour hands-on workshop where participants vibe-build a transit-crisis ADK agent on the Gemini Enterprise Agent Platform using Antigravity.

- **[M0 · Setup](https://kazunori279.github.io/gcp-eoa/BwG-track2/m0.html)** — Environment setup, Developer Knowledge MCP, data download, "before" screenshot, and a shared `plan.md` checklist (10 min)
- **[M1 · Build](https://kazunori279.github.io/gcp-eoa/BwG-track2/m1.html)** — Scaffold agent + 3 tools + system instruction + local playground (30 min)
- **[M2 · Scale](https://kazunori279.github.io/gcp-eoa/BwG-track2/m2.html)** — Deploy to Agent Runtime, Sessions, Memory Bank, Code Execution (25 min)
- **[M3 · Govern](https://kazunori279.github.io/gcp-eoa/BwG-track2/m3.html)** — Registry, Identity, Gateway, Model Armor (25 min)
- **[M4 · Optimize](https://kazunori279.github.io/gcp-eoa/BwG-track2/m4.html)** — Eval scenarios, LLM-as-judge scoring, instruction optimization (20 min)
- **[M5 · Engage](https://kazunori279.github.io/gcp-eoa/BwG-track2/m5.html)** — Publish to Gemini Enterprise (10 min)

Each module's hands-on prompts are copy-paste blocks prefixed `Module X Step Y:`. In M0 the coding agent creates a `plan.md` checklist of every module/step and works one step at a time, so it doesn't run ahead.

> **Status — under testing.** Modules are being validated against the live lab. The Developer Knowledge MCP grounding may be blocked by lab runtime policy; when it is, M0 sets up a `dk.py` direct-access fallback. Native MCP enablement is pending confirmation with the lab organizer.

Open the HTML files in any browser — no dependencies or build step required.

## For AI coding agents

Before editing `eoa-workshops.html`, read [`.skills/html-first-output/SKILL.md`](.skills/html-first-output/SKILL.md) for the HTML-first output conventions used in this project.
