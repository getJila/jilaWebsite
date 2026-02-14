# Jila — Canonical Design Principles (v1) (Anti-drift)

These principles are **canonical** across all Jila surfaces (mobile app, web portal, backend-driven UI patterns).

Rule: other docs must **reference** these principles and must not restate alternate versions inside per-platform sections.

---

## UX-P-001 — Contrast is King (outdoor-first)

- **Status**: DECIDED
- **Decision (v1)**:
  - Treat **direct-sunlight readability** as a first-class requirement.
  - Test critical screens **in direct sunlight** on a low-cost Android device; if color distinctions vanish, the design
    fails.
  - In “Solar Mode” / high-contrast light theme, default to **true black text on white** (`#000000` on `#FFFFFF`) for
    body text and critical numbers.
  - For “trust-first” flows (monitoring, pairing, ordering), prefer **dark navy / deep blue-teal** on white for headers
    and primary navigation so the UI reads as calm and engineered, not playful.
- **Deep references**:
  - `docs/ux/jila_design_decision_register.md` (UX-D-046)
  - `docs/ux/jila_design_guide.md` (Contrast & Solar Mode)

## UX-P-002 — Localize, don’t stereotype (subtle motifs only)

- **Status**: DECIDED
- **Decision (v1)**:
  - “Local” visuals must never become caricature or overwhelm comprehension.
  - If cultural motifs are used (e.g., textile-inspired geometry), they must be **subtle** (≈5–10% opacity), **vector**,
    and must never reduce text contrast or compete with primary content.
  - Prefer the “Blueprints of Life” line-art language and keep backgrounds lightweight.
- **Deep references**:
  - `docs/ux/jila_design_decision_register.md` (UX-D-041, UX-D-032)
  - `docs/ux/jila_design_guide.md` (“Lite Imperative”)

## UX-P-003 — Respect regional trauma & color associations (red caution)

- **Status**: DECIDED
- **Decision (v1)**:
  - Never rely on **bright red** alone to communicate urgency/destruction; always pair with icon + label (UX-P-005).
  - Prefer **terracotta/maroon** for warnings and destructive emphasis where culturally safer; reserve bright red for
    strict “error/failure” semantics.
  - Reserve **true red** for **alerts and failures only** (not “attention”, not “progress”).
- **Deep references**:
  - `docs/ux/jila_design_decision_register.md` (UX-D-010 semantic tokens; UX-D-021 redundant encoding)

## UX-P-004 — Optimize for energy (OLED true-black dark)

- **Status**: DECIDED
- **Decision (v1)**:
  - Support an **OLED-friendly true-black** dark mode surface (`#000000`) to reduce battery usage on OLED devices.
  - Avoid “Material Design grey” dark backgrounds such as `#121212` for the primary canvas.
- **Deep references**:
  - `docs/ux/jila_design_decision_register.md` (UX-D-010 token mapping guidance)

## UX-P-005 — Double-code colors (color + symbol + text)

- **Status**: DECIDED
- **Decision (v1)**:
  - Color is never the only signal: every status must be communicated via **redundant encoding**:
    - color + icon/symbol + short label (or text).
  - Examples:
    - Error/Failure: red + warning/triangle icon + “Error”
    - Success: green + checkmark + “OK”
- **Deep references**:
  - `docs/ux/jila_design_decision_register.md` (UX-D-021; UX-D-046 non-negotiables)

## UX-P-006 — Avoid subtle gradients (flat solids + borders)

- **Status**: DECIDED
- **Decision (v1)**:
  - Avoid subtle gradients for core UI surfaces; they band on low-end displays.
  - Prefer **flat, solid colors** with explicit **borders/dividers** for hierarchy.
  - If an exception is needed (rare), it must be explicit, tested on low-end hardware, and must not carry meaning by
    color alone.
  - **Explicit exception (v1)**:
    - Gradients are allowed **only** inside the **tank fill visualization** (a visualization surface, not a UI surface),
      and only when they are (a) explicit, (b) tested on low-end devices, and (c) do not reduce comprehension of the
      numeric reading or the Last Known State treatment.

## UX-P-007 — Build trust with Blue/Teal + Green (water-first palette)

- **Status**: DECIDED
- **Decision (v1)**:
  - Our default brand “trust palette” is the **blue–teal family** (water + calm + competence).
  - Use blue/teal for:
    - primary navigation and headers (calming blues)
    - information and trust surfaces (links, safe highlights)
  - Use green for:
    - confirmations and success states
    - “safe to proceed” CTAs (when semantically appropriate)
- **Notes**:
  - This is a preference guidance layered on top of contrast requirements (UX-P-001 / UX-D-046).

## UX-P-008 — Limit the palette (3–4 semantic colors; consistent meaning)

- **Status**: DECIDED
- **Decision (v1)**:
  - Keep the “semantic palette” constrained to **3–4 key colors**, with stable meaning:
    - **Blue/Teal** = information / trust / primary navigation
    - **Green** = success / positive action
    - **Warm Orange / Terracotta** = attention / progress / “in motion”
    - **Red** = alerts / failure only
  - Avoid introducing additional bright hues that compete with meaning:
    - no purple, pink, or “sunshine” yellow as semantic colors.
- **Why it matters**: reduces cognitive load and helps low-literacy users sort/identify by consistent color association.

## UX-P-009 — Prefer industrial clarity over fragile aesthetics

- **Status**: DECIDED
- **Decision (v1)**:
  - We operate in low-trust markets: prefer **engineered, industrial** visual language:
    - clear containers/cards with visible edges
    - obvious affordances (controls should look pressable)
    - avoid hairlines and overly airy layouts that read as ephemeral/fragile
- **Deep references**:
  - `docs/ux/jila_design_guide.md` (Trust & Stability posture — “Visual weight (industrial stability)”)

## UX-P-010 — Be honest about uncertainty (no false precision)

- **Status**: DECIDED
- **Decision (v1)**:
  - When showing estimates (e.g., “days remaining”), present them as estimates and always show freshness/confidence or
    data gaps; never imply false precision.
  - Prefer conservative defaults when uncertainty could cause harm.
- **Deep references**:
  - `docs/ux/jila_application_ux_guidelines.md` (“Days remaining is an estimate” + “Avoid harm from bad estimates”)
