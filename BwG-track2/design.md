---
version: alpha
name: Rush Hour Workshop
description: >-
  Design system for the "Build with Gemini World Tour · Track 2" workshop
  module pages (m0–m5). A bright, dense, technical-but-friendly docs/workshop
  aesthetic: dark fixed sidebar, gradient hero, white cards on a light-grey
  canvas, colour-coded modules, and dark code/prompt blocks.
colors:
  # Surfaces & text
  bg: "#f8f9fa"            # page canvas (light grey)
  surface: "#ffffff"       # cards, steps, tables
  border: "#dee2e6"        # hairline borders / dividers
  text: "#212529"          # primary text (near-black)
  text-muted: "#6c757d"    # captions, metadata
  # Semantic accents (each has a -light tint for fills/backgrounds)
  accent: "#1a73e8"        # primary blue · M1 BUILD
  accent-light: "#e8f0fe"
  danger: "#dc3545"        # red · disruption / "why a chatbot fails"
  danger-light: "#fde8ea"
  success: "#198754"       # green · M2 SCALE · expected results / done-when
  success-light: "#d1e7dd"
  warning: "#fd7e14"       # orange · cautions / reconcile
  warning-light: "#fff3e0"
  govern: "#7c3aed"        # purple · M3 GOVERN
  govern-light: "#ede9fe"
  optimize: "#0891b2"      # cyan · M4 OPTIMIZE
  optimize-light: "#e0f7fa"
  engage: "#b45309"        # amber/brown · M5 ENGAGE (note: deeper than warning)
  engage-light: "#fef3c7"
  # Dark-UI palette (sidebar + code/agent blocks)
  sidebar-bg: "#1a1f2e"
  sidebar-text: "#c5cdd8"
  sidebar-link: "#8b97a8"
  sidebar-active: "#8ab4f8"
  sidebar-footer: "#4a5568"
  code-bg: "#1e1e1e"        # .prompt-block background
  code-text: "#d4d4d4"
  agent-bg: "#1b2838"       # .agent-ctx background
  agent-text: "#c5e1f5"
  agent-border: "#2d4a6f"
  inline-code-bg: "#eef1f5" # inline <code>
typography:
  hero-h1:
    fontFamily: '"Segoe UI", system-ui, -apple-system, sans-serif'
    fontSize: 2.2rem
    fontWeight: 800
    lineHeight: 1.2
  hero-sub:
    fontFamily: '"Segoe UI", system-ui, -apple-system, sans-serif'
    fontSize: 1.05rem
    fontWeight: 400
    lineHeight: 1.6
  h2:
    fontFamily: '"Segoe UI", system-ui, -apple-system, sans-serif'
    fontSize: 1.3rem
    fontWeight: 700
    lineHeight: 1.3
  card-title:           # .card h3
    fontFamily: '"Segoe UI", system-ui, -apple-system, sans-serif'
    fontSize: 1.1rem
    fontWeight: 700
    lineHeight: 1.3
  step-title:           # .step h3
    fontFamily: '"Segoe UI", system-ui, -apple-system, sans-serif'
    fontSize: 1.05rem
    fontWeight: 700
    lineHeight: 1.3
  body:
    fontFamily: '"Segoe UI", system-ui, -apple-system, sans-serif'
    fontSize: 1rem
    fontWeight: 400
    lineHeight: 1.6
  body-sm:              # checklist / table cells / callouts
    fontFamily: '"Segoe UI", system-ui, -apple-system, sans-serif'
    fontSize: 0.9rem
    fontWeight: 400
    lineHeight: 1.6
  code:                 # .prompt-block / .agent-ctx / .tool-sig
    fontFamily: '"SF Mono", "Cascadia Code", "Fira Code", monospace'
    fontSize: 0.85rem
    fontWeight: 400
    lineHeight: 1.55
  label-caps:           # hero-track, ba-label, agent-ctx-label
    fontFamily: '"Segoe UI", system-ui, -apple-system, sans-serif'
    fontSize: 0.75rem
    fontWeight: 700
    lineHeight: 1.3
    letterSpacing: 1px
  nav:                  # sidebar links
    fontFamily: '"Segoe UI", system-ui, -apple-system, sans-serif'
    fontSize: 0.82rem
    fontWeight: 500
    lineHeight: 1.3
rounded:
  sm: 4px               # inline code, step-time, prompt labels
  md: 6px               # tool-sig
  lg: 10px              # DEFAULT (--radius): cards, callouts, steps, code blocks
  pill: 20px            # hero-time, hero-pill (12px variant also used)
  full: 9999px          # nav dots, step-num, check-icon (rendered via 50%)
spacing:
  xs: 0.25rem
  sm: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  card-pad: 1.5rem      # .card / .step internal padding
  container-max: 960px  # main content max width
  sidebar-w: 220px      # fixed sidebar width
  bp-tablet: 900px      # sidebar collapses below this
  bp-mobile: 700px      # hero shrinks, grids stack
shadow:
  sm: "0 1px 3px rgba(0,0,0,.08), 0 1px 2px rgba(0,0,0,.06)"   # --shadow (cards)
  lg: "0 4px 12px rgba(0,0,0,.1)"                              # --shadow-lg
components:
  card:
    backgroundColor: "{colors.surface}"
    borderColor: "{colors.border}"
    rounded: "{rounded.lg}"
    padding: "{spacing.card-pad}"
  accent-card:          # tool-card / artifact-card / govern-card pattern
    backgroundColor: "{colors.surface}"
    borderColor: "{colors.accent}"   # swap to module accent
    rounded: "{rounded.lg}"
    padding: 1.25rem
  step-num:
    backgroundColor: "{colors.accent}"
    textColor: "{colors.surface}"
    size: 36px
    rounded: "{rounded.full}"
  prompt-block:
    backgroundColor: "{colors.code-bg}"
    textColor: "{colors.code-text}"
    rounded: "{rounded.lg}"
    padding: 1rem 1.25rem
  agent-ctx:
    backgroundColor: "{colors.agent-bg}"
    textColor: "{colors.agent-text}"
    borderColor: "{colors.agent-border}"
    rounded: "{rounded.lg}"
    padding: 1.25rem 1.5rem
  copy-btn:
    backgroundColor: "#333"
    textColor: "#aaa"
    borderColor: "#555"
    rounded: "{rounded.sm}"
---

# Rush Hour Workshop — Design System (`design.md`)

This document is the source of truth for the look & feel of the **Track 2
workshop module pages** (`m0.html` … `m5.html`). It is written so that a person
or an AI agent can build a **new module page (e.g. `m6.html`) that matches the
existing set**, without reverse-engineering the HTML.

It follows the [Google Labs `DESIGN.md` spec](https://github.com/google-labs-code/design.md):
machine-readable **tokens** live in the YAML front-matter above; the prose below
explains **how and when** to use them. Beyond the spec it adds two practical
extras for this project: a **copy-paste component library** and two **page
templates**.

> **Golden rule:** every module page is one HTML file with **inline `<style>`**
> and **no external dependencies** (no frameworks, no web fonts, no JS libs).
> Everything ships self-contained. Keep it that way.

---

## Overview

**Personality:** confident, modern, technical, and *calm under pressure* — the
pages teach people to build software during a simulated transit crisis, so the
UI should feel like a well-organised mission-control briefing, not a marketing
site.

**Audience:** developers / "platform builders" working hands-on in a 2-hour
guided workshop.

**Feel:** **information-dense but scannable.** Lots of short cards, numbered
steps, tables, code blocks, and small hand-drawn diagrams. Generous whitespace
*inside* white cards; tight rhythm *between* them. Bright on light-grey, with one
loud gradient hero per page and dark "terminal" blocks for anything copy-pasteable.

**The defining motif — colour-coded modules.** The workshop is a 6-stage arc and
each stage owns one accent colour. This mapping is used *everywhere* (sidebar
dots, phase chips, hero gradient hints, accent-cards, recap badges):

| Module | Phase | Accent token | Hex |
|---|---|---|---|
| M0 | Start / Setup | `text-muted` (neutral grey) | `#6c757d` |
| M1 | **BUILD** | `accent` (blue) | `#1a73e8` |
| M2 | **SCALE** | `success` (green) | `#198754` |
| M3 | **GOVERN** | `govern` (purple) | `#7c3aed` |
| M4 | **OPTIMIZE** | `optimize` (cyan) | `#0891b2` |
| M5 | **ENGAGE** | `engage` (amber) | `#b45309` |

When you create a new page, **pick its module accent first** — it drives the
sidebar dot, the hero pills, accent-cards, and the recap badge.

---

## Colors

The palette is a light, neutral base (`bg`/`surface`/`border`/`text`) plus a set
of **semantic accents that always travel in pairs**: a saturated line/text
colour and a matching `-light` tint for fills. This pairing is the backbone of
every coloured component.

- **Accent / Blue (`#1a73e8`)** — the default interactive colour: links,
  step numbers, primary buttons, M1. Fill with `accent-light` (`#e8f0fe`).
- **Danger / Red (`#dc3545`)** — disruption, failure, "what is happening",
  the St Pancras alert. Fill `danger-light` (`#fde8ea`).
- **Success / Green (`#198754`)** — confirmation: "Expected Result", "Done
  When", M2 SCALE. Fill `success-light` (`#d1e7dd`).
- **Warning / Orange (`#fd7e14`)** — cautions and the "reconcile" step. Fill
  `warning-light` (`#fff3e0`).
- **Govern / Purple (`#7c3aed`)**, **Optimize / Cyan (`#0891b2`)**,
  **Engage / Amber (`#b45309`)** — module identity colours for M3/M4/M5, each
  with its `-light` tint.

**Dark-UI sub-palette.** Three things are dark on every page: the **sidebar**
(`#1a1f2e`), **code/prompt blocks** (`#1e1e1e`), and **agent-context blocks**
(`#1b2838`, the "paste into Antigravity" panels). These provide contrast anchors
in an otherwise bright layout.

**Implementation.** All colours are declared once as CSS custom properties in
`:root` and referenced via `var(--token)`. Always reference the variable; never
hardcode a hex in component CSS.

```css
:root {
  --bg: #f8f9fa;        --surface: #ffffff;   --border: #dee2e6;
  --text: #212529;      --text-muted: #6c757d;
  --accent: #1a73e8;    --accent-light: #e8f0fe;
  --danger: #dc3545;    --danger-light: #fde8ea;
  --success: #198754;   --success-light: #d1e7dd;
  --warning: #fd7e14;   --warning-light: #fff3e0;
  --govern: #7c3aed;    --govern-light: #ede9fe;
  --optimize: #0891b2;  --optimize-light: #e0f7fa;
  --engage: #b45309;    --engage-light: #fef3c7;
}
```

---

## Typography

**One UI font, one mono font** — both system stacks, so nothing is downloaded.

- **UI:** `"Segoe UI", system-ui, -apple-system, sans-serif`
- **Mono:** `"SF Mono", "Cascadia Code", "Fira Code", monospace` (code, prompts,
  tool signatures)

Body text is `1rem / line-height 1.6`. Weights are used decisively: **400** for
body, **700** for headings/emphasis, **800** for the hero `h1` and big labels.
There are no light weights.

Scale (largest → smallest): hero `h1` `2.2rem/800` → `h2` `1.3rem/700` (with a
2px bottom border) → card `h3` `1.1rem` → step `h3` `1.05rem` → body `1rem` →
small UI `0.9rem` → code `0.85rem` → caps labels `0.75rem`.

**Uppercase caps-labels** (`text-transform:uppercase; letter-spacing:1–2px;
font-weight:700; small size; muted colour`) are a recurring device for kickers
and section eyebrows: `hero-track`, `ba-label`, `agent-ctx-label`, `prompt-label`.

```css
h2 { font-size: 1.3rem; font-weight: 700; margin-bottom: 1rem;
     color: var(--text); border-bottom: 2px solid var(--border);
     padding-bottom: .5rem; }
```

---

## Layout

**Two-column shell:** a fixed **220px dark sidebar** on the left + a fluid
**main content** area (`margin-left: 220px`). Inside main content, copy is capped
to a **960px centered container** (`.container { max-width: 960px; margin: 0
auto; padding: 1.5rem 1rem; }`). The hero spans the full main-content width
(edge to edge); only the body content is constrained.

**Vertical rhythm:** cards/steps stack with `margin-bottom: 1.25rem`. Major
content groups are separated by a `.section-divider` (a `2px` top border with
`margin-top: 2rem`).

**Grids** are used sparingly via CSS grid: the 5-up `phase-bar`, the 2-up
`before-after`, and the SVG diagrams. No grid framework.

**Responsive (two breakpoints):**
- `≤ 900px` (`bp-tablet`): **sidebar hidden**, `main-content` margin removed.
- `≤ 700px` (`bp-mobile`): hero `h1` shrinks to `1.5rem`, `before-after` and
  multi-column grids collapse to one column, `phase-bar` goes 5→3 columns, step
  number repositions to the top.

```css
.main-content { margin-left: 220px; }
.container    { max-width: 960px; margin: 0 auto; padding: 1.5rem 1rem; }
@media (max-width: 900px) {
  .sidebar { display: none; }
  .main-content { margin-left: 0; }
}
```

---

## Elevation & Depth

Depth is **mostly flat**, conveyed by three layered techniques rather than heavy
shadows:

1. **Surface contrast** — white cards (`surface`) float on the grey canvas (`bg`).
2. **Soft shadows** — a single subtle token on raised cards: `--shadow: 0 1px
   3px rgba(0,0,0,.08), 0 1px 2px rgba(0,0,0,.06)`. A stronger `--shadow-lg`
   exists for emphasis but is used rarely.
3. **Left-border accents** — `callout`, `step-expected`, and `arc-card` use a
   `4–5px` coloured left border instead of shadow to signal type/importance.

The darkest elements (sidebar, code, agent blocks) read as the "deepest" layer
purely through colour, not shadow.

---

## Shapes

**Soft, rounded, friendly.** The default radius is **`10px`** (`--radius`),
applied to nearly every container: cards, steps, callouts, code blocks, phase
chips, accent-cards. Smaller chrome uses `4px` (inline code, step-time pills,
prompt labels) or `6px` (tool signatures). Fully round (`50%` / `9999px`) is
reserved for **nav dots**, **step numbers** (36px circle), and **checkbox
icons** (22px square with 4px radius). Pills (hero time/pills) use `12–20px`.

SVG diagram boxes echo the language with `rx="8"`–`rx="12"` rounded rectangles.

```css
:root {
  --radius: 10px;
  --shadow: 0 1px 3px rgba(0,0,0,.08), 0 1px 2px rgba(0,0,0,.06);
  --shadow-lg: 0 4px 12px rgba(0,0,0,.1);
}
```

---

## Components

This is the reusable component library. Each entry lists **what it's for**,
**when to use it**, and a **copy-paste snippet**. All snippets assume the
`:root` tokens and base CSS from the [Page Templates](#page-templates) are
present. CSS for each component is included once below; the templates bundle the
full stylesheet.

### Foundation components (every page)

#### 1. Sidebar nav

Fixed 220px dark navigation listing all six modules. Each link has a coloured
**nav-dot** (the module accent), a label, and a `nav-sub` (duration + topic).
The current page's link gets `class="active"` (blue text + left border + tinted
bg). Identical on every page except which link is `active`.

```html
<aside class="sidebar">
  <div class="sidebar-header">
    <div class="title">"Rush Hour"</div>
    <div class="subtitle">Track 2 &middot; Platform Builders</div>
  </div>
  <nav>
    <a href="m0.html"><span class="nav-dot" style="background:#6c757d;"></span>
      <span class="nav-label">M0 &middot; Start Here<span class="nav-sub">10 min &middot; Mission &amp; setup</span></span></a>
    <a href="m1.html"><span class="nav-dot" style="background:#1a73e8;"></span>
      <span class="nav-label">M1 &middot; Build<span class="nav-sub">30 min &middot; Agent &amp; tools</span></span></a>
    <a href="m2.html"><span class="nav-dot" style="background:#198754;"></span>
      <span class="nav-label">M2 &middot; Scale<span class="nav-sub">25 min &middot; Deploy &amp; state</span></span></a>
    <a href="m3.html"><span class="nav-dot" style="background:#7c3aed;"></span>
      <span class="nav-label">M3 &middot; Govern<span class="nav-sub">25 min &middot; Security</span></span></a>
    <a href="m4.html"><span class="nav-dot" style="background:#0891b2;"></span>
      <span class="nav-label">M4 &middot; Optimize<span class="nav-sub">20 min &middot; Quality flywheel</span></span></a>
    <a href="m5.html"><span class="nav-dot" style="background:#b45309;"></span>
      <span class="nav-label">M5 &middot; Engage<span class="nav-sub">10 min &middot; Publish</span></span></a>
  </nav>
  <div class="sidebar-footer">Build with Gemini World Tour</div>
</aside>
```

```css
.sidebar { position: fixed; top: 0; left: 0; width: 220px; height: 100vh;
  background: #1a1f2e; color: #c5cdd8; overflow-y: auto; z-index: 100;
  display: flex; flex-direction: column; }
.sidebar-header { padding: 1.25rem 1rem .75rem; border-bottom: 1px solid rgba(255,255,255,.08); }
.sidebar-header .title { font-size: .85rem; font-weight: 800; color: #fff; letter-spacing: .5px; line-height: 1.3; }
.sidebar-header .subtitle { font-size: .7rem; color: #6b7a8d; margin-top: .2rem; }
.sidebar nav { flex: 1; padding: .5rem 0; }
.sidebar a { display: flex; align-items: center; gap: .6rem; padding: .6rem 1rem;
  color: #8b97a8; text-decoration: none; font-size: .82rem; font-weight: 500;
  border-left: 3px solid transparent; transition: background .12s, color .12s, border-color .12s; }
.sidebar a:hover { background: rgba(255,255,255,.05); color: #d0d8e3; }
.sidebar a.active { background: rgba(26,115,232,.12); color: #8ab4f8; border-left-color: #8ab4f8; font-weight: 700; }
.sidebar a .nav-dot { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; }
.sidebar a .nav-sub { display: block; font-size: .7rem; font-weight: 400; color: #5e6b7a; }
.sidebar a.active .nav-sub { color: #6a9bd8; }
.sidebar-footer { padding: .75rem 1rem; border-top: 1px solid rgba(255,255,255,.08); font-size: .68rem; color: #4a5568; }
```

#### 2. Hero

Full-width gradient banner at the top of main content. The diagonal gradient
(`#1a237e → #1565c0 → #0097a7`) is constant; a thin **rainbow stripe** sits at
the bottom edge via `::after`. Contains a caps **track** kicker, a **module**
line, the big `h1`, a `hero-sub`, and a rounded `hero-time` chip. Hands-on pages
(m1–m5) add a row of `hero-pills` (tech tags).

```html
<div class="hero">
  <div class="hero-track">Build with Gemini World Tour &middot; Track 2 &middot; Platform Builders</div>
  <div class="hero-module">Module 1</div>
  <h1>BUILD</h1>
  <p class="hero-sub">One-line summary of what this module does.</p>
  <div class="hero-time">30 minutes &middot; 0:10 &ndash; 0:40 &middot; Hands-on</div>
  <div class="hero-pills">           <!-- optional, hands-on pages only -->
    <span class="hero-pill">ADK</span>
    <span class="hero-pill">gemini-3.5-flash</span>
  </div>
</div>
```

```css
.hero { background: linear-gradient(135deg, #1a237e 0%, #1565c0 50%, #0097a7 100%);
  color: #fff; padding: 2.5rem 2rem 2rem; text-align: center; position: relative; overflow: hidden; }
.hero::after { content: ""; position: absolute; bottom: 0; left: 0; right: 0; height: 4px;
  background: repeating-linear-gradient(90deg, var(--danger) 0 60px, var(--warning) 60px 120px,
    var(--success) 120px 180px, var(--accent) 180px 240px); }
.hero-track { font-size: .8rem; letter-spacing: 2px; text-transform: uppercase; opacity: .7; margin-bottom: .25rem; }
.hero-module { font-size: 1rem; opacity: .85; margin-bottom: .3rem; }
.hero h1 { font-size: 2.2rem; font-weight: 800; margin-bottom: .4rem; }
.hero-sub { font-size: 1.05rem; opacity: .85; max-width: 680px; margin: 0 auto; }
.hero-time { display: inline-block; margin-top: .75rem; background: rgba(255,255,255,.15);
  padding: .3rem 1rem; border-radius: 20px; font-size: .85rem; font-weight: 600; }
.hero-pills { display: flex; justify-content: center; gap: .5rem; margin-top: .75rem; flex-wrap: wrap; }
.hero-pill { background: rgba(255,255,255,.12); padding: .2rem .7rem; border-radius: 12px; font-size: .75rem; font-weight: 600; }
```

#### 3. Card

The workhorse container. White, bordered, rounded, soft shadow. The `h3` title
takes a leading emoji `.icon`. Compose everything else (tables, prompts,
diagrams, lists) inside cards.

```html
<div class="card">
  <h3><span class="icon">&#x1F6A8;</span> Card Title</h3>
  <p>Body copy with <strong>emphasis</strong> and <code>inline code</code>.</p>
</div>
```

```css
.card { background: var(--surface); border: 1px solid var(--border); border-radius: var(--radius);
  padding: 1.5rem; margin-bottom: 1.25rem; box-shadow: var(--shadow); }
.card h3 { font-size: 1.1rem; margin-bottom: .75rem; display: flex; align-items: center; gap: .5rem; }
.card h3 .icon { font-size: 1.3rem; }
code { background: #eef1f5; padding: .15rem .4rem; border-radius: 4px; font-family: var(--mono); font-size: .88em; }
```

#### 4. Callout

Left-border banner for asides. Five variants by semantic colour:
`callout-info` (blue), `callout-danger`, `callout-success`, `callout-warning`,
plus module variants `callout-govern` / `callout-optimize` / `callout-engage`.
Use `callout-info` for objectives, `callout-warning` for fallbacks/cautions.

```html
<div class="callout callout-info">
  <div class="callout-title">Objective</div>
  <p>What the learner achieves in this module.</p>
</div>
```

```css
.callout { border-radius: var(--radius); padding: 1rem 1.25rem; margin-bottom: 1.25rem; border-left: 4px solid; }
.callout-danger  { background: var(--danger-light);  border-color: var(--danger); }
.callout-info    { background: var(--accent-light);  border-color: var(--accent); }
.callout-success { background: var(--success-light); border-color: var(--success); }
.callout-warning { background: var(--warning-light); border-color: var(--warning); }
.callout-govern  { background: var(--govern-light);  border-color: var(--govern); }
.callout-optimize{ background: var(--optimize-light);border-color: var(--optimize); }
.callout-engage  { background: var(--engage-light);  border-color: var(--engage); }
.callout-title { font-weight: 700; margin-bottom: .35rem; }
```

#### 5. Step (numbered)

A card with a circled number badge in the gutter. Used for the "Setup/Build in N
Steps" sequences. Optional `step-time` pill, and an `step-expected` green
result panel at the end.

```html
<div class="step">
  <div class="step-num">1</div>
  <span class="step-time">3 min</span>
  <h3>Step Title</h3>
  <p>What to do.</p>
  <div class="step-expected">
    <h4>Expected Result</h4>
    <p>What success looks like.</p>
  </div>
</div>
```

```css
.step { background: var(--surface); border: 1px solid var(--border); border-radius: var(--radius);
  padding: 1.5rem; margin-bottom: 1.25rem; box-shadow: var(--shadow); position: relative; padding-left: 4.5rem; }
.step-num { position: absolute; left: 1.25rem; top: 1.4rem; width: 36px; height: 36px; border-radius: 50%;
  background: var(--accent); color: #fff; font-weight: 800; font-size: 1rem;
  display: flex; align-items: center; justify-content: center; }
.step h3 { font-size: 1.05rem; margin-bottom: .5rem; }
.step-time { display: inline-block; background: var(--accent-light); color: var(--accent);
  font-size: .75rem; font-weight: 700; padding: .15rem .5rem; border-radius: 4px; margin-bottom: .5rem; }
.step-expected { background: var(--success-light); border-left: 4px solid var(--success);
  border-radius: var(--radius); padding: 1rem 1.25rem; margin-top: .75rem; }
.step-expected h4 { font-size: .9rem; font-weight: 700; color: var(--success); margin-bottom: .5rem; }
```

#### 6. Prompt / code block

Dark "terminal" block for shell commands and copy-paste prompts. A caps
`prompt-label` (top-right) names the language; a `copy-btn` wires to
`copyBlock()`. Variant `prompt-antigravity` uses a subtle blue-grey gradient for
"paste into Antigravity" prompts.

```html
<div class="prompt-block" id="cmd-example">
  <button class="copy-btn" onclick="copyBlock('cmd-example')">Copy</button>
  <span class="prompt-label">shell</span>! echo "your command here"
</div>
```

```css
.prompt-block { background: #1e1e1e; color: #d4d4d4; padding: 1rem 1.25rem; border-radius: var(--radius);
  font-family: var(--mono); font-size: .85rem; line-height: 1.55; margin: .75rem 0; position: relative;
  overflow-x: auto; white-space: pre-wrap; word-break: break-word; }
.prompt-label { position: absolute; top: .4rem; right: .6rem; font-size: .65rem; font-weight: 700;
  color: #888; text-transform: uppercase; letter-spacing: 1px; }
.prompt-antigravity { background: linear-gradient(135deg, #1a1f2e, #252b3b); border: 1px solid #3a4255; }
```

#### 7. Agent-context block + copy button

The "Paste into AGY/Antigravity" panels — large multi-line briefings the learner
pastes into the coding agent. Darker blue than code blocks, with a labelled
chip. Wrap in `.agent-section` (which is `position: relative`) so the `copy-btn`
anchors correctly.

```html
<div class="card agent-section">
  <button class="copy-btn" onclick="copyBlock('ctx-id')">Copy</button>
  <div class="agent-ctx" id="ctx-id"><span class="agent-ctx-label">Paste into AGY</span>
Your multi-line context / instruction text goes here,
preserved exactly as written.</div>
</div>
```

```css
.agent-ctx { background: #1b2838; color: #c5e1f5; border: 2px solid #2d4a6f; border-radius: var(--radius);
  padding: 1.25rem 1.5rem; margin: 1rem 0; font-family: var(--mono); font-size: .82rem; line-height: 1.6;
  white-space: pre-wrap; word-break: break-word; }
.agent-ctx-label { display: inline-block; background: #2d4a6f; color: #e0f0ff; font-size: .7rem; font-weight: 700;
  letter-spacing: 1.5px; text-transform: uppercase; padding: .2rem .6rem; border-radius: 4px; margin-bottom: .75rem; }
.agent-section { position: relative; }
.copy-btn { position: absolute; top: .4rem; right: .5rem; background: #333; color: #aaa; border: 1px solid #555;
  border-radius: 4px; padding: .2rem .5rem; font-size: .7rem; cursor: pointer; font-family: var(--font); }
.copy-btn:hover { background: #444; color: #ddd; }
```

#### 8. Data table

Standard bordered table for reference grids (timelines, file columns, fields).
Header row tinted grey; rows highlight on hover. Rows are sometimes tinted with a
module `-light` colour to colour-code a timeline.

```html
<table class="data">
  <thead><tr><th>Column A</th><th>Column B</th></tr></thead>
  <tbody>
    <tr><td>value</td><td>value</td></tr>
  </tbody>
</table>
```

```css
table.data { width: 100%; border-collapse: collapse; font-size: .88rem; margin: .75rem 0; }
table.data th, table.data td { padding: .55rem .75rem; border: 1px solid var(--border); text-align: left; }
table.data th { background: #f1f3f5; font-weight: 700; }
table.data tr:hover td { background: #f8f9fa; }
```

#### 9. Checklist (interactive)

Toggle-able checkboxes, used for the "Mentor Checkpoint — Done When" lists.
Clicking the icon toggles a `checked` class (drawn checkmark). Inline `onclick`,
no library.

```html
<ul class="checklist">
  <li><span class="check-icon" onclick="this.classList.toggle('checked')"></span>
      <div>An item to verify is complete.</div></li>
</ul>
```

```css
.checklist { list-style: none; padding: 0; }
.checklist li { padding: .55rem 0; border-bottom: 1px solid var(--border); display: flex;
  align-items: flex-start; gap: .6rem; font-size: .93rem; }
.checklist li:last-child { border-bottom: none; }
.check-icon { width: 22px; height: 22px; flex-shrink: 0; border: 2px solid var(--accent); border-radius: 4px;
  margin-top: 2px; cursor: pointer; display: flex; align-items: center; justify-content: center; transition: background .15s; }
.check-icon.checked { background: var(--accent); }
.check-icon.checked::after { content: "\2713"; color: #fff; font-size: .75rem; font-weight: 800; }
```

#### 10. Done-when box

Green-bordered summary block that closes a module — the success checklist.
Usually wraps a `.checklist`.

```html
<div class="done-when">
  <h3>Mentor Checkpoint &mdash; Done When:</h3>
  <ul class="checklist"> ... </ul>
</div>
```

```css
.done-when { background: var(--success-light); border: 2px solid var(--success); border-radius: var(--radius);
  padding: 1.25rem 1.5rem; margin-top: 1.5rem; }
.done-when h3 { color: var(--success); font-size: 1rem; margin-bottom: .6rem; }
```

### Structural / navigational components

#### 11. Phase bar

A 5-up grid of coloured chips showing the BUILD→SCALE→GOVERN→OPTIMIZE→ENGAGE
arc. Mostly on the intro page. Collapses to 3 columns on mobile.

```html
<div class="phase-bar">
  <div class="phase-chip phase-build">M1 &middot; BUILD</div>
  <div class="phase-chip phase-scale">M2 &middot; SCALE</div>
  <div class="phase-chip phase-govern">M3 &middot; GOVERN</div>
  <div class="phase-chip phase-optimize">M4 &middot; OPTIMIZE</div>
  <div class="phase-chip phase-engage">M5 &middot; ENGAGE</div>
</div>
```

```css
.phase-bar { display: grid; grid-template-columns: repeat(5, 1fr); gap: 6px; margin-bottom: 1.5rem; }
.phase-chip { text-align: center; padding: .65rem .4rem; border-radius: var(--radius);
  font-size: .78rem; font-weight: 700; letter-spacing: .5px; }
.phase-build    { background: var(--accent-light);  color: var(--accent); }
.phase-scale    { background: var(--success-light); color: var(--success); }
.phase-govern   { background: var(--govern-light);  color: var(--govern); }
.phase-optimize { background: var(--optimize-light);color: var(--optimize); }
.phase-engage   { background: var(--warning-light); color: #b45309; }
```

#### 12. Before / after

Two-column comparison: a dashed grey "before" card and a solid green "after"
card. Used to show the "empty platform now → full platform by 2:00" story.
Stacks on mobile.

```html
<div class="before-after">
  <div class="ba-card ba-before">
    <div class="ba-label">Now (M0)</div>
    <ul class="ba-items"><li>Starting state</li></ul>
  </div>
  <div class="ba-card ba-after">
    <div class="ba-label">By 2:00 (M5)</div>
    <ul class="ba-items"><li>End state</li></ul>
  </div>
</div>
```

```css
.before-after { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; margin: 1rem 0; }
.ba-card { border-radius: var(--radius); padding: 1.25rem; text-align: center; }
.ba-before { background: #f1f3f5; border: 2px dashed var(--border); }
.ba-after { background: var(--success-light); border: 2px solid var(--success); }
.ba-label { font-size: .75rem; font-weight: 700; text-transform: uppercase; letter-spacing: 1px; margin-bottom: .5rem; }
.ba-before .ba-label { color: var(--text-muted); }
.ba-after .ba-label { color: var(--success); }
.ba-items { font-size: .88rem; color: var(--text); }
.ba-items li { list-style: none; padding: .2rem 0; }
```

#### 13. Module recap "beats"

The closing pattern on hands-on pages (m1–m5): four numbered "beats" that
narrate **What You Typed → What Ran Under the Hood → What You Can See → Why It
Matters**. Each beat is a `card` whose `h3` opens with a coloured `beat-badge`.

```html
<h2>Module Recap &mdash; BUILD</h2>
<div class="card">
  <h3><span class="beat-badge beat-1" style="margin-left:0;">Beat 1</span> What You Typed</h3>
  <p>...</p>
</div>
<div class="card">
  <h3><span class="beat-badge beat-2" style="margin-left:0;">Beat 2</span> What Ran Under the Hood</h3>
  <p>...</p>
</div>
<!-- Beat 3 (beat-3): What You Can See in the Console -->
<!-- Beat 4 (beat-4): Why It Matters -->
```

```css
.beat-badge { display: inline-block; font-size: .68rem; font-weight: 700; padding: .15rem .5rem;
  border-radius: 4px; margin-left: .5rem; }
.beat-1 { background: #e8f0fe; color: #1a73e8; }
.beat-2 { background: #fff3e0; color: #b45309; }
.beat-3 { background: #d1e7dd; color: #198754; }
.beat-4 { background: #ede9fe; color: #7c3aed; }
```

#### 14. Accent-card (module-specific variants)

A heavier card with a **2px accent border** and an **accent-coloured `h4`**,
used to spotlight the module's key objects. Each module names its own variant but
they are the *same pattern* — only the accent colour changes:

| Variant | Module | Border/title colour |
|---|---|---|
| `tool-card` | M1 | `accent` (blue) |
| `artifact-card` | M2 | `success` (green) |
| `govern-card` | M3 | `govern` (purple) |
| `arc-card` | M5 | per-row left border |

To make a new one, copy the pattern and swap the colour token.

```html
<div class="tool-card">
  <h4>get_schedule(station, time)</h4>
  <p>What this object does.</p>
  <code class="tool-sig">def get_schedule(station: str, window: int) -> list</code>
</div>
```

```css
.tool-card { background: var(--surface); border: 2px solid var(--accent); border-radius: var(--radius);
  padding: 1.25rem; margin-bottom: 1rem; }
.tool-card h4 { font-size: 1rem; color: var(--accent); margin-bottom: .4rem; }
.tool-sig { font-family: var(--mono); font-size: .82rem; background: #f1f3f5; padding: .4rem .6rem;
  border-radius: 6px; margin: .4rem 0; display: block; }
/* M2: .artifact-card { ... border: 2px solid var(--success); } .artifact-card h4 { color: var(--success); } */
/* M3: .govern-card  { ... border: 2px solid var(--govern);  } .govern-card  h4 { color: var(--govern);  } */
```

#### 15. Section divider + page section heading

Group major content blocks with a `section-divider` wrapper; introduce each with
an `h2` (auto-gets a 2px bottom border).

```html
<div class="section-divider">
  <h2>The Journey</h2>
  ...cards...
</div>
```

```css
.section-divider { border-top: 2px solid var(--border); margin-top: 2rem; padding-top: .5rem; }
```

---

## SVG diagrams (styled pattern)

The pages use small, **hand-authored inline `<svg>`** diagrams (network map,
tool-flow, file-join graph, module arc) instead of images. New diagrams should
follow these conventions so they match:

- **Wrapper:** always inside `<div class="map-wrap">`; SVG is responsive via
  `viewBox` + `max-width`/`height:auto`. No fixed pixel width on the element.
- **Boxes:** rounded rects, `rx="8"`–`rx="12"`. **Fill = the `-light` token,
  stroke = the matching saturated token**, `stroke-width:1.5` (use `2` to
  emphasise). This makes diagrams colour-coded the same way as the rest of the UI.
- **Type:** `font-family:system-ui`. Title `font-size:10–11, font-weight:700`
  in the box's accent colour; detail text `font-size:8–9, fill:#333` or `#666`.
- **Connectors:** thin lines (`stroke-width:1.5`) with arrowheads defined once
  in `<defs><marker>`; colour the marker to match the source. Dashed red
  (`stroke-dasharray:6,3`, `#dc3545`) means "disrupted".
- **Legend:** small lines + `font-size:9, fill:#888` text at the bottom.

```css
.map-wrap { text-align: center; margin: 1rem 0; overflow-x: auto; }
.map-wrap svg { max-width: 100%; height: auto; }
```

Annotated example (a two-node flow with a coloured arrow):

```html
<div class="map-wrap">
  <svg viewBox="0 0 360 90" xmlns="http://www.w3.org/2000/svg" style="max-width:340px;">
    <defs>
      <marker id="ah" markerWidth="8" markerHeight="6" refX="8" refY="3" orient="auto">
        <path d="M0,0 L8,3 L0,6" fill="#1a73e8"/>      <!-- arrowhead = accent -->
      </marker>
    </defs>
    <!-- box: fill = accent-light, stroke = accent -->
    <rect x="10" y="20" width="140" height="50" rx="10" fill="#e8f0fe" stroke="#1a73e8" stroke-width="1.5"/>
    <text x="80" y="42" text-anchor="middle" font-family="system-ui" font-size="11" font-weight="700" fill="#1a73e8">Tool 1</text>
    <text x="80" y="58" text-anchor="middle" font-family="system-ui" font-size="9" fill="#666">"what should happen"</text>
    <!-- connector -->
    <line x1="150" y1="45" x2="208" y2="45" stroke="#1a73e8" stroke-width="1.5" marker-end="url(#ah)"/>
    <!-- result box: stronger stroke for emphasis -->
    <rect x="210" y="20" width="140" height="50" rx="10" fill="#e8f0fe" stroke="#1a73e8" stroke-width="2"/>
    <text x="280" y="48" text-anchor="middle" font-family="system-ui" font-size="11" font-weight="700" fill="#1a73e8">Verified Answer</text>
  </svg>
</div>
```

---

## Page Templates

Two archetypes cover all six pages. Both share the same `<head>`, `:root`, base
CSS, sidebar, and copy script — only the body content differs.

### Shared shell (head + base CSS + script)

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>M6 — Title | Rush Hour Workshop</title>
<style>
  :root {
    --bg:#f8f9fa; --surface:#fff; --border:#dee2e6; --text:#212529; --text-muted:#6c757d;
    --accent:#1a73e8; --accent-light:#e8f0fe; --danger:#dc3545; --danger-light:#fde8ea;
    --success:#198754; --success-light:#d1e7dd; --warning:#fd7e14; --warning-light:#fff3e0;
    --govern:#7c3aed; --govern-light:#ede9fe; --optimize:#0891b2; --optimize-light:#e0f7fa;
    --engage:#b45309; --engage-light:#fef3c7;
    --font:"Segoe UI",system-ui,-apple-system,sans-serif;
    --mono:"SF Mono","Cascadia Code","Fira Code",monospace;
    --radius:10px; --shadow:0 1px 3px rgba(0,0,0,.08),0 1px 2px rgba(0,0,0,.06);
    --shadow-lg:0 4px 12px rgba(0,0,0,.1);
  }
  *,*::before,*::after { box-sizing:border-box; margin:0; padding:0; }
  body { font-family:var(--font); color:var(--text); background:var(--bg); line-height:1.6; }
  .main-content { margin-left:220px; }
  .container { max-width:960px; margin:0 auto; padding:1.5rem 1rem; }
  @media (max-width:900px){ .sidebar{display:none;} .main-content{margin-left:0;} }
  @media (max-width:700px){
    .hero h1{font-size:1.5rem;} .before-after{grid-template-columns:1fr;}
    .phase-bar{grid-template-columns:repeat(3,1fr);}
    .step{padding-left:1.25rem;padding-top:3.5rem;} .step-num{top:1rem;left:1.25rem;}
    .container{padding:1rem .75rem;}
  }
  h2 { font-size:1.3rem; margin-bottom:1rem; color:var(--text); border-bottom:2px solid var(--border); padding-bottom:.5rem; }
  p { margin-bottom:.75rem; } strong { font-weight:700; }
  ul,ol { margin-left:1.25rem; margin-bottom:.75rem; } li { margin-bottom:.25rem; }
  /* + paste the component CSS you use: .sidebar, .hero, .card, .callout, .step,
     .prompt-block, .agent-ctx, table.data, .checklist, .done-when, etc. */
</style>
</head>
<body>
  <!-- [Sidebar nav — component #1, set the current page's link to class="active"] -->
  <div class="main-content">
    <!-- [Hero — component #2] -->
    <div class="container">
      <!-- [Page body — see archetype A or B below] -->
    </div>
  </div>
  <script>
    function copyBlock(id){
      const el=document.getElementById(id); const clone=el.cloneNode(true);
      clone.querySelectorAll('.agent-ctx-label,.prompt-label,.copy-btn').forEach(n=>n.remove());
      const text=clone.textContent.trim();
      navigator.clipboard.writeText(text).then(()=>{
        const btn=el.querySelector('.copy-btn')||el.parentElement.querySelector('.copy-btn');
        if(btn){const o=btn.textContent; btn.textContent='Copied!'; setTimeout(()=>btn.textContent=o,1500);}
      });
    }
  </script>
</body>
</html>
```

### Archetype A — Intro / overview page (like `m0`)

Neutral grey accent. Body flow:

1. `phase-bar` (the 5-stage arc)
2. `callout-info` — **Objective**
3. `<h2>` section + several `card`s (scenario, why, deliverable) with SVG diagrams
4. `section-divider` → `<h2>` + timeline `table.data` + artifacts SVG
5. `section-divider` → `<h2>` "Setup in N Steps" → numbered `step`s (each with
   `step-time`, `agent-ctx`/`prompt-block`, `step-expected`)
6. `done-when` box with interactive `checklist`

### Archetype B — Hands-on module page (like `m1`–`m5`)

Module accent colour (blue/green/purple/cyan/amber). Body flow:

1. Hero includes `hero-pills` (tech tags) + `Hands-on` in `hero-time`
2. `callout-info` — **Objective**
3. Optional `callout-warning` — one-time environment setup
4. `<h2>` "Build/… in N Steps" → numbered `step`s; spotlight key objects with the
   module's **accent-card** (`tool-card`/`artifact-card`/`govern-card`/…) and use
   `prompt-antigravity` for agent prompts
5. `<h2>` **Module Recap** → the four **beats** (#13)
6. `done-when` box with `checklist`

---

## Do's and Don'ts

**Do**
- Keep each page a **single self-contained `.html`** with inline `<style>` — no
  external CSS/JS/fonts.
- **Choose the module accent first** and apply it consistently: sidebar dot,
  hero pills, accent-card, recap badge.
- Reference **tokens** (`var(--accent)`) — never hardcode hex in component CSS.
- Pair colours correctly: saturated token for **lines/text/borders**, the
  `-light` token for **fills/backgrounds**.
- Put a **`copy-btn`** on every `prompt-block` and `agent-ctx` the learner is
  meant to copy, and give the block a unique `id`.
- Use semantic components for meaning: `step-expected`/`done-when` = green,
  `callout-warning` = cautions/fallbacks, `callout-danger` = the crisis.
- Set the current page's sidebar link to `class="active"` and keep the six
  nav entries identical across pages.
- Keep diagrams as inline `<svg>` in `.map-wrap`, colour-coded with the tokens.
- Lead `card`/`step` titles with a single emoji `.icon` for quick scanning.

**Don't**
- Don't introduce a new font, a CSS framework, or a JS dependency.
- Don't invent new accent colours — reuse the seven semantic tokens.
- Don't mix a module's accent with another module's (e.g. green title on the M3
  govern page) except in the shared phase-bar / arc visuals.
- Don't hardcode widths on SVGs — use `viewBox` + `max-width` so they stay responsive.
- Don't exceed the **960px** content container or remove the **220px** sidebar
  offset (except via the responsive breakpoints).
- Don't use light font weights; the system is 400 / 700 / 800 only.
- Don't drop the two breakpoints (`900px` sidebar, `700px` hero/grids) — pages
  must stay usable on mobile.
- Don't put long copy in dark blocks; reserve `prompt-block`/`agent-ctx` for
  commands and paste-able prompts only.

