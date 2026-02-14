---
title: Jila UI — Screenshot Design Contrast Report (v1 draft)
status: DRAFT
last_updated: 2026-01-14
inputs:
  - "Screenshots: Alerts, Users & Access, Dashboard (dark + light), Auth verification/login"
canonical_refs:
  - ../ux/jila_theme_and_brand_tokens_v1.md
  - ../ux/jila_canonical_design_principles.md
  - ../ux/jila_design_decision_register.md
  - ./01_design_tokens_spec.md
  - ./02_component_patterns_spec.md
---

## Purpose

Extract the implied design system from the provided screenshots and contrast it against Jila’s canonical token/pattern
docs, to identify contradictions and recommend a merged, stable UX/UI guideline set.

Scope note: this is **design-system alignment** only (no backend/API behavior impact).

Standalone mock (pixel recreation aid):
- `docs/design/mocks/login_email_verified_v1.html` (Auth login / “Email Verificado” screenshot recreation)
  - Note: the mock keeps the screenshot’s white-on-teal primary CTA label (see C3 for the contrast doctrine mismatch).

---

## A) Screenshot-derived design elements (what the UI is “saying”)

### A1) Themes & surfaces

- **Dual theme posture**: both a dark “operations” mode and a light “clean admin” mode are shown.
- **Dark mode**: deep navy canvas; elevated cards/panels with subtle borders; teal accent for CTAs; status chips/cards.
- **Light mode**: very pale (almost-white) canvas with soft tinted panels; cards feel “airy” with soft shadow and
  rounded corners; teal accent for CTAs.

### A2) Layout & information hierarchy

- **Persistent left navigation**: icon + label, active item highlighted as a rounded “pill”.
- **Global command/search** on the top bar (“Pesquisar …” with keyboard shortcut hint).
- **Page header pattern**: large title + short subtitle + primary action(s) on the right.
- **Dashboard composition**: KPI row (4 cards), then primary monitoring panel + secondary panels (sites, alerts,
  quick actions).

### A3) Components & states

- **KPI stat cards**: small icon + big number + label; consistent sizing and equal weight.
- **Search + filters**: search input + segmented tabs/chips + sort dropdown; list/map toggle on some pages.
- **Empty states**: icon/illustration + headline + short guidance + one primary CTA (e.g., “Adicionar Reservatório”).
- **Inline error banner**: prominent red/pink banner (“Nao foi possivel carregar users”) with a retry/refresh affordance.
- **Auth verification**: multi-slot OTP entry with grouping (e.g., `XXX-XXX`) and resend countdown.

---

## B) Canonical design constraints (current “source of truth”)

### B1) Contrast + Solar Mode (non-negotiable)

- Solar Mode aims at direct sunlight: “true black text on white” for body text and critical numbers, and AAA contrast.
- Primary CTA on teal should prefer **dark** text for contrast, not white, unless contrast is verified.

References:
- `docs/ux/jila_canonical_design_principles.md` (UX-P-001)
- `docs/ux/jila_design_decision_register.md` (UX-D-046)
- `docs/ux/jila_theme_and_brand_tokens_v1.md` (“onPrimary guidance”)
- `docs/design/01_design_tokens_spec.md` (“onPrimary guidance”)

### B2) Gradients are discouraged for core UI surfaces

- Flat solids + explicit borders/dividers are preferred for hierarchy; subtle gradients band on low-end displays.

Reference:
- `docs/ux/jila_canonical_design_principles.md` (UX-P-006)

### B3) Minimal semantic palette + redundant encoding

- Use consistent semantics (success/warning/error/critical/info); do not introduce “new semantic hues”.
- Status must never be color-only: always color + icon + label.

References:
- `docs/ux/jila_theme_and_brand_tokens_v1.md` (semantic meaning contract)
- `docs/ux/jila_canonical_design_principles.md` (UX-P-005, UX-P-008)
- `docs/design/02_component_patterns_spec.md` (status + alerts rules)

---

## C) Contradictions / tension points (screenshots vs canonical docs)

This section intentionally highlights *mismatches*; it’s the raw input for negotiation and decision-making.

### C1) Light theme “Solar Mode” surface colors (potential mismatch)

- **Screenshot behavior**: light mode appears slightly tinted (mint/blue gradients) with white cards.
- **Canonical guidance**: Solar Mode emphasizes `#FFFFFF` background and black body text, with `surface_solar = #EAF3FF`
  as the “pale sky surface”.

Recommendation:
- Treat the screenshots’ light theme as **Solar Mode-aligned**, but enforce:
  - `background_solar = #FFFFFF` as the canvas default.
  - Use `surface_solar = #EAF3FF` for panels where you want separation, and keep “paper” cards white only if contrast
    and borders are explicit.

Why:
- Preserves direct-sunlight posture and reduces low-end gradient banding risk.

### C2) Subtle gradients on light surfaces (contradiction unless we carve an exception)

- **Screenshot behavior**: multiple screens show soft gradients on the canvas/background.
- **Canonical guidance**: avoid subtle gradients for core UI surfaces (banding risk).

Merge options:
- Option A (recommended): make backgrounds **flat** solids and rely on borders/dividers + elevation tokens.
- Option B (explicit exception): allow a **single** background gradient token for *non-meaning-bearing* page canvas only,
  but require:
  - tested on low-end displays
  - no semantic meaning
  - no text placed on low-contrast zones

### C3) Primary button text color on teal (likely mismatch)

- **Screenshot behavior**: several teal CTAs appear to use **white** label text on teal.
- **Canonical guidance**: teal is light; `onPrimary` should be **dark** for AAA outdoors; do not default to white.

Recommendation:
- Standardize `onPrimary` for teal contained buttons to a dark color (black or deep navy) and reserve white labels for
  **secondary (deep blue)** contained buttons.

### C4) Error banner styling (needs alignment to semantic + redundant encoding)

- **Screenshot behavior**: error banner is strongly tinted red/pink; readability varies across dark vs light examples.
- **Canonical guidance**: errors must be redundant (icon + label + message), and semantic meanings must be stable.

Recommendation:
- Implement error banners as a consistent `Alert` pattern:
  - leading icon (e.g., warning triangle)
  - short title (“Erro”)
  - concise message
  - one recovery action (“Tentar novamente”)

### C5) Navigation active state (possible mismatch with icon state doctrine)

- **Screenshot behavior**: active nav uses a teal-highlight pill with icon+label; icon may not switch outline/filled.
- **Canonical guidance** (cross-surface): solid/filled active icon and outline inactive (plus redundant cue).

Recommendation:
- Keep the pill highlight (it works well outdoors), but also adopt:
  - filled icon for active
  - outline icon for inactive
  - label weight change (semi-bold) for active

---

## D) Merge recommendations (token + pattern decisions to lock)

### D1) Define “Solar Mode Web” explicitly (no drift)

Decide and document:
- Canvas: `background_solar = #FFFFFF` (flat).
- Panel: `surface_solar = #EAF3FF` (flat).
- Card-on-panel: allow white with explicit border (`outline_light`) OR treat cards as `surface_solar` with elevation.

### D2) Ban gradients in core surfaces (unless we formalize a single exception token)

If the team wants the screenshot vibe:
- Formalize **one** web-only “canvasGradient” token as an exception and gate its usage.
Otherwise:
- Remove gradients and rely on borders, elevation, and spacing/radius consistency.

### D3) Lock the CTA contrast doctrine

- Teal contained CTA: dark text (AAA posture).
- Blue contained CTA: white text (where contrast holds).
- Define focus ring + hover alphas using computed values (already allowed in token mapping spec).

### D4) Standardize “empty / loading / error” components

The screenshots already align to the doc pattern:
- Empty: icon + headline + one primary CTA.
- Error: inline alert + one recovery action.
- Loading: skeletons (avoid full-page spinners on monitoring surfaces).

### D5) Suggested “merge posture” (pragmatic)

- Treat **dark mode** screenshots as the closest match to the canonical token intent (midnight navy + glass/borders).
- Treat **light mode** screenshots as **Solar Mode-adjacent**, but enforce the canonical contrast + anti-gradient rules.
- Only accept deviations if we explicitly record them as web-only derived tokens or a documented exception (with rationale).

---

## E) Open questions to resolve (fast decisions that prevent drift)

1) Light theme intent: is it strictly “Solar Mode” (outdoor high-contrast), or an “admin light theme” for office use?
2) Do we want any gradients at all? If yes, define the one allowed gradient token and its usage constraints.
3) CTA text on teal: confirm we commit to dark text (recommended) even if it diverges slightly from some existing UI.
4) Navigation icon state: do we enforce filled/outline pairs on web nav as well (recommended for cross-surface coherence)?
