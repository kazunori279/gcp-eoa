# Era of Agents — Hands-on Workshop Series

### Build with Gemini World Tour — Track 2: Rush Hour

2-hour hands-on workshop where participants vibe-build a transit-crisis ADK agent on the Gemini Enterprise Agent Platform using Antigravity.

## Demo abstract

*A one-page orientation — the gist of the opening and closing voiceover — for anyone about to watch or run the demo.*

**The problem.** It's peak evening at **London St Pancras International** and a signal failure at the station throat has halted cross-border rail. Eurostar services to **Paris, Brussels, Amsterdam, and Cologne** are cancelled or severely delayed, and hundreds of stranded travelers are all asking one question — *"Will I still make it, and how?"* A general-purpose chatbot can't answer it: it can't look up the **live schedule**, reconcile it against a **real-time disruption feed**, or **compute a reroute** across the network — so it confidently hallucinates a train that was cancelled an hour ago.

**What the demo builds.** A production **transit-crisis agent** on the **Gemini Enterprise Agent Platform**, built end-to-end with the **Antigravity** coding agent and the **Agent Development Kit (ADK)**. The agent joins the static timetable (GTFS) with the live disruption feed on trip ID, reconciles what *should* happen against what *is* happening, and proactively computes alternatives — giving each traveler one calm, grounded, actionable recommendation instead of a hallucination.

**The outcome.** In about two hours the *same* agent is carried through the platform's full lifecycle — **built → scaled → governed → optimized → published** — ending as a governed, deployed, evaluated enterprise agent that business users can chat with directly inside **Gemini Enterprise**. The through-line: one platform spans the entire path from developer code to a business-user chat experience.

**Products, tools & capabilities shown**

| Stage | What's demonstrated |
|---|---|
| **Build** | **Antigravity CLI** + **ADK** — vibe-build the agent, three deterministic tools (schedule lookup, disruption check, reroute), and the system instruction; test in the local playground |
| **Scale** | **Agent Runtime** (managed deploy) · **Sessions** · **Memory Bank** (cross-session personalization) · **Code Execution sandbox** (ad-hoc analytics) |
| **Govern** | **Agent Registry** · **Agent Identity** (SPIFFE-attested, least-privilege) · **Model Armor** (jailbreak + PII shielding) |
| **Optimize** | **Agent Evaluation** — crisis-scenario simulation at scale + an LLM-as-judge grounding score (the quality flywheel) |
| **Engage** | **Gemini Enterprise** — publish the agent so business users can use it |
| Throughout | **Developer Knowledge MCP** (grounded Google Cloud docs) · **Gemini 3.x Flash** |

The five modules below walk this journey step by step.

- **[M0 · Setup](https://kazunori279.github.io/gcp-eoa/BwG-track2/m0.html)** — Environment setup, Developer Knowledge MCP, data download, "before" screenshot, and a shared `plan.md` checklist (12 min)
- **[M1 · Build](https://kazunori279.github.io/gcp-eoa/BwG-track2/m1.html)** — Scaffold agent + 3 tools + system instruction + local playground (25 min)
- **[M2 · Scale](https://kazunori279.github.io/gcp-eoa/BwG-track2/m2.html)** — Deploy to Agent Runtime, Sessions, Memory Bank, Code Execution (30 min)
- **[M3 · Govern](https://kazunori279.github.io/gcp-eoa/BwG-track2/m3.html)** — Registry, Identity, Gateway, Model Armor (15 min)
- **[M4 · Optimize](https://kazunori279.github.io/gcp-eoa/BwG-track2/m4.html)** — Eval loop concept, crisis-scenario simulation, and grading the agent with an LLM-as-judge grounding score — measurement only, no redeploy (18 min)
- **[M5 · Engage](https://kazunori279.github.io/gcp-eoa/BwG-track2/m5.html)** — Publish to Gemini Enterprise (10 min)

Each module's hands-on prompts are copy-paste blocks prefixed `Module X Step Y:`. In M0 the coding agent creates a `plan.md` checklist of every module/step and works one step at a time, so it doesn't run ahead.

Open the HTML files in any browser — no dependencies or build step required.
