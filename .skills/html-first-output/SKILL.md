---
name: html-first-output
description: >-
  Generate rich, self-contained HTML files instead of Markdown for specs, plans,
  reports, reviews, explainers, prototypes, and any human-readable document.
  Use when producing documents meant to be read, shared, or interacted with —
  not when writing README files, CHANGELOGs, or git-conventional docs.
license: Apache-2.0
metadata:
  author: kazunori279
  version: "1.0"
---

# HTML-First Output

When producing specs, plans, reports, explainers, reviews, or any document meant to be read by humans, **default to generating a self-contained HTML file instead of Markdown** unless the user explicitly asks for Markdown.

## Why HTML over Markdown

- **Information density.** HTML supports tables, CSS styling, SVG illustrations, interactive JavaScript elements, spatial layouts, and embedded images. Without HTML, you resort to ASCII diagrams and flat lists.
- **Readability.** A 100-line Markdown file gets skimmed; an HTML page with tabs, color, diagrams, and visual hierarchy gets read.
- **Shareability.** HTML files open in any browser and can be shared via link. Markdown requires a separate renderer.
- **Interactivity.** HTML with sliders, toggles, drag-and-drop, or live-preview lets the user explore options and copy results back.

## When to generate HTML

| Use case | What to include |
|---|---|
| **Specs and plans** | Mockups, data-flow diagrams (SVG), code snippets, tabbed sections. For large efforts, produce multiple HTML files (exploration, design, implementation plan) rather than one giant document. |
| **Code review** | Rendered diffs with inline annotations, color-coded severity, flowcharts, module diagrams. |
| **Design and prototypes** | Interactive controls (sliders, color pickers, toggles). Include a "copy parameters" button so chosen values can be pasted back. |
| **Reports and research** | Diagrams, annotated code snippets, a "gotchas" section. Good for feature summaries, incident reports, weekly status, explainers. |
| **Custom editing interfaces** | Single-file throwaway editors for specific data (ticket triage boards, config editors, prompt tuners). Always include an export mechanism: "copy as JSON", "copy as Markdown", or "copy diff" button. |

## Required patterns

- **Self-contained** — inline all CSS and JS. No external dependencies, CDN links, or build steps. The file must work when opened from the local filesystem.
- **Mobile-responsive** layouts when the file may be shared.
- **SVG** for diagrams and flowcharts, not ASCII art.
- **Tabs or accordions** to organize large documents instead of long scrolling pages.
- **Side-by-side grids** for comparison tasks.
- **"Copy as …" buttons** for any structured data editing (copy as JSON, copy as prompt, copy diff).

## Example prompts

- "Generate 6 distinctly different approaches — vary layout, tone, and density — and lay them out as a single HTML file in a grid so I can compare them side by side."
- "Create a thorough implementation plan in an HTML file, with mockups, data flow diagrams, and important code snippets."
- "Help me review this PR by creating an HTML artifact. Render the actual diff with inline margin annotations, color-code findings by severity."
- "Prototype a new checkout button. Create an HTML file with several sliders and options. Give me a copy button to copy the parameters that worked well."
- "Read the relevant code and produce a single HTML explainer page: a diagram of the token-bucket flow, the 3–4 key code snippets annotated, and a 'gotchas' section."
- "Make me an HTML file with each ticket as a draggable card across Now / Next / Later / Cut columns. Add a 'copy as Markdown' button."
- "Build a form-based editor for the feature flag config, group flags by area, show dependencies. Add a 'copy diff' button."
- "Make a side-by-side editor: editable prompt on the left, three sample inputs on the right that re-render the filled template live."

## When to still use Markdown

- README files and git-conventional docs (CHANGELOG, CONTRIBUTING).
- Files that must be rendered by GitHub/GitLab natively.
- When the user explicitly requests Markdown.
