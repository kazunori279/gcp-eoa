# Workshop Readability Review — "Rush Hour" (Track 2)

**Scope:** M0–M5 HTML modules, read end-to-end from the point of view of a *participant* sitting in the 2-hour live workshop. Focus is **ease-of-understanding and readability of the text** — not whether the prompts actually run.

**Reviewer takeaway:** The series is genuinely strong — clear narrative arc, consistent visual system, excellent "what to watch for" / "what just happened" / Mentor Checkpoint scaffolding, and honest callouts about lab quirks. The issues below are mostly *friction*, not *failure*: undefined jargon, a few cross-module contradictions, and a content-volume-vs-time mismatch that will make participants feel behind. Fixing the P1 items would meaningfully reduce confusion in the room.

---

## Priority 1 — Will actively confuse participants (fix first)

### 1.1 "AGY" is used ~everywhere but never defined
- **Where:** First appears at `m0.html:760` (`Cloud Shell / AGY can default…`), then used heavily in every module's prose and paste blocks.
- **Problem:** "Antigravity" and "AGY" are both used, but the abbreviation is never introduced. A first-time participant has to *infer* that AGY = Antigravity. New tool + new acronym = avoidable cognitive load in the first 10 minutes.
- **Fix:** On first use in M0, write it out once: "Antigravity (**AGY**)". Cheap, one-time, removes a recurring stumble.

### 1.2 M4 says "measure only, no fix" but M5 claims you made a fix
- **Where:** M4 is explicit that you only *measure*: "here we stop at the measurement" (`m4.html:345`, `m4.html:507`), plus the "No fix, no deploy" bullet (`m4.html:502`). But M5's recap says M4 = **"graded eval, one targeted fix, before/after"** (`m5.html:383`) and **"before/after compare · grounding fix + pytest"** (`m5.html:513`). The M0 `plan.md` also seeds this: "Step 3: Grade, fix, and prove one cycle".
- **Problem:** A participant who just did M4 (measurement only) reaches M5 and is told they did a before/after fix they never performed. Direct contradiction; erodes trust in the recap.
- **Fix:** Pick one story. Since M4 deliberately stops at measurement for time, change the M5 recap row and arc-card to match ("graded eval + flagged ungrounded sentences"), and align the `plan.md` line in `m0.html` (Step 3 → "Grade and read the score table").

### 1.3 The agent has three different names
- **Where:** Project name `transit-assistant` (`m1.html:559`), display name **"Transit-Crisis Agent"** (`m0.html:879`, `m5.html:369`), and prose "transit agent" / "Rush Hour agent" elsewhere.
- **Problem:** In M5 the participant is told to scaffold `transit-assistant` but then to *select* "Transit-Crisis Agent" in the Gemini Enterprise UI (`m5.html:369`). If the displayed name doesn't obviously map to the project they named, they'll hesitate ("is this mine?").
- **Fix:** Either standardize on one name, or add a single sentence in M5 noting "your project `transit-assistant` shows up as 'Transit-Crisis Agent' in the portal." At minimum make the M5 selection step acknowledge the project name.

### 1.4 Time budgets vs. actual content volume
- **Where:** Every module header (`10 min`, `30 min`, `25 min`…), and the M0 timeline table (`m0.html:677`).
- **Problem:** The stated minutes don't match the on-page work. Examples:
  - **M0 "10 min":** 5 steps (3+2+3+3+2 = 13 min of step-times) *plus* the entire Crisis Briefing + Journey reading. Realistically 20+ min. This is the densest "setup" I've seen labeled 10 min.
  - **M2 "25 min":** step-times sum to ~28 min and include a 5–10 min deploy wait and **four** post-deploy test scenarios.
  - **M1 "30 min":** step-times sum to ~28 min with little slack for the inevitable AGY retries.
- **Impact on readability:** Participants who track the clock will feel perpetually behind, which makes them *skim* exactly the explanatory prose that gives the workshop its value.
- **Fix:** Either right-size the headline numbers, or add a "core path vs. if-you-have-time" marker so people know what's skippable under time pressure. (M3/M4 are already marked Optional — extend that thinking to *within* M0/M2.)

---

## Priority 2 — Noticeable friction / inconsistency

### 2.1 "BSGO" is never expanded — and it silently drops "Engage"
- **Where:** "The BSGO Arc You'll Traverse" (`m0.html:1244`), "BSGO journey" (`m5.html:376`), "The Full BSGO Arc" (`m5.html:407`).
- **Problem:** Two issues at once: (a) the acronym is never spelled out, and (b) BSGO = Build/Scale/Govern/Optimize — it **excludes Engage (M5)**, even though M5 is where the acronym is most used and the payoff lives.
- **Fix:** Expand on first use, and consider "BSGOE" or just drop the acronym in favor of the full "Build → Scale → Govern → Optimize → Engage" arc you already use elsewhere.

### 2.2 The "Journey" arc heading omits Engage
- **Where:** `m0.html:670` "The Journey — Build → Scale → Govern → Optimize" and `m5.html:527` "Build → Scale → Govern → Optimize lifecycle…" — both drop Engage, while `m5.html:466` includes it.
- **Problem:** The headline framing a participant reads first (M0) presents a 4-stage journey, but the workshop is 5 modules. Small, but it undercuts M5's importance and is internally inconsistent.
- **Fix:** Make the arc consistently 5-stage (include Engage) everywhere, or clearly cast Engage as "the payoff after the lifecycle."

### 2.3 Optional modules vs. a fixed sequential timeline
- **Where:** M3 and M4 are labeled **(Optional)** in the nav/hero, but the M0 timeline (`m0.html:677`) and the M5 BSGO arc show all modules as a fixed sequential 0:00→2:00 schedule.
- **Problem:** A participant can't easily tell *what the minimum path is* if they're short on time. "Optional" in the sidebar conflicts with a wall-to-wall timeline.
- **Fix:** In the M0 timeline, visually mark M3/M4 as optional and state the minimum path (M0→M1→M2→M5). Reassure that M5 only depends on M2's deploy (which is already true and stated in M5).

### 2.4 M2 is the heaviest module and over-repeats its one idea
- **Where:** The "deploy once / test locally first" message appears in the Objective, the "you deploy ONCE" heads-up (`m2.html:511`), "The Leap" (`m2.html:633`), Step 4, Step 5, and the recap.
- **Problem:** The message is good and worth stating — but it's repeated ~5 times, which adds length to the already-longest module and buries the *new* information in each section.
- **Fix:** State the "deploy once" rationale strongly once (the heads-up box), then reference it briefly. Reclaim the space to make Step 6's four scenarios less dense.

### 2.5 Dense, long "Paste into AGY" blocks can intimidate
- **Where:** e.g. M0 Step 1 (~55 lines), M3 Step 2 (~45 lines), M2 Steps 1/5/6, M3 Step 3.
- **Reality check:** These are copy-paste, so participants *shouldn't* read them line by line — which mitigates the issue. But several blocks mix the action with deep rationale (why a file is overwritten, SPIFFE nuances, endpoint overrides). The wall of dark monospace reads as "scary" at a glance.
- **Fix:** Keep the surrounding plain-language prose doing the explaining (it already does this well), and consider a one-line italic lead-in on the longest blocks: "*You don't need to read this — just copy it. Summary: …*". You partially do this ("treat it as a black box") — apply it consistently to the longest blocks.

---

## Priority 3 — Polish / lower impact

### 3.1 Model-ID mix (3.5 agent, 2.5 judge) may raise an eyebrow
- **Where:** Agent uses `gemini-3.5-flash` (`m1.html:560`); M4 judge uses `gemini-2.5-flash` (`m4.html:455`).
- **Note:** M4 already justifies 2.5 ("reliably enabled in lab projects"), so this is defensible. But a sharp participant will wonder why the *judge* is an older model than the agent. A half-sentence ("the judge model just needs to be lab-enabled; it's independent of your agent's model") would preempt the question.

### 3.2 Metaphors that may not land for non-native speakers
- **Where:** "Cockpit" ("Verify Your Cockpit", `m0.html:974`), "vibe-build / vibe-coding", "The Leap".
- **Note:** Fine for the intended audience and adds energy, but "cockpit" for "your local toolchain" is a stretch on first read. Low priority; flag only if the audience is internationally mixed.

### 3.3 Jargon density in M3 (security)
- **Where:** SPIFFE, DPoP, mutual TLS, CEL, IAP, SGP, Context-Aware Access — several land in quick succession (`m3.html:309`, `m3.html:586`, etc.).
- **Note:** M3 is (Optional) and aimed at platform builders, so some density is expected. But the 4-layer SVG + four govern-cards + the control-plane cards stack a lot of acronyms fast. Consider a one-line gloss on the two most load-bearing (SPIFFE, Model Armor) since the rest are "context, go read the docs."

### 3.4 M1 step flow is interrupted by the tool reference
- **Where:** Step 1 (Scaffold) → a full "The 3 Tools — In Detail" section → Step 2 (Tools). 
- **Note:** The reference content is excellent, but inserting it *between* numbered steps briefly breaks the "do step 1, do step 2" rhythm. Consider a tiny signpost at the end of Step 1 ("Before Step 2, here's what the three tools are —") so the reader knows the reference is interstitial, not a step they're skipping.

### 3.5 Minor: M0 section comment says "SETUP IN 4 STEPS" but it's 5
- **Where:** HTML comment near `m0.html:753` vs. visible heading "Setup in 5 Steps". Comment-only, invisible to participants — fix for maintainer sanity, not readability.

---

## What's working well (keep doing this)

- **Consistent per-step scaffolding:** "Paste into AGY" → "Expected Result" → "What to watch for" → "What just happened" is a reliable, learnable rhythm. Participants always know where they are.
- **Mentor Checkpoint "Done When" boxes** end every module with a concrete self-check — excellent for a room moving at different speeds.
- **The before/after framing** (empty console in M0 → full platform in M5) gives the whole workshop a satisfying spine.
- **Honest lab-reality callouts** (e.g. built-in vs. managed sandbox in `m2.html:790`, broad IAM roles you should *expect to see flagged* in `m3.html:453`, intermittent Cloud Shell auth in `m2.html:908`) set accurate expectations and prevent "is it broken?" panic.
- **The "Stuck? reference solution" escape hatches** in M1/M2 are exactly right for a timed, vibe-coding workshop where AGY may stall.
- **Visual system** (phase bar, SVG diagrams, color-coded module identity, sidebar nav) is consistent and aids orientation.
- **Module recaps (the 4 "Beats")** reinforce *what you typed / what ran / what you can see / why it matters* — strong pedagogy.

---

## Suggested order of attack

1. Define **AGY** once in M0 (1.1) — 1 line, highest confusion-per-fix ratio.
2. Resolve the **M4-vs-M5 "fix" contradiction** (1.2) — pick the measure-only story and align M5 + plan.md.
3. Reconcile the **agent naming** in M5's selection step (1.3).
4. Add an **optional-path / time-reality note** to the M0 timeline (1.4 + 2.3).
5. Expand or drop **BSGO**, and make the **arc consistently 5-stage** (2.1 + 2.2).
6. Trim **M2's repetition** (2.4) and add lead-ins to the **longest paste blocks** (2.5).
7. P3 polish as time allows.
