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
  - `docs/design/jila_design_decision_register.md` (UX-D-046)
  - `docs/ux/jila_design_guide.md` (Contrast & Solar Mode)

## UX-P-002 — Localize, don’t stereotype (subtle motifs only)

- **Status**: DECIDED
- **Decision (v1)**:
  - “Local” visuals must never become caricature or overwhelm comprehension.
  - If cultural motifs are used (e.g., textile-inspired geometry), they must be **subtle** (≈5–10% opacity), **vector**,
    and must never reduce text contrast or compete with primary content.
  - Prefer the “Blueprints of Life” line-art language and keep backgrounds lightweight.
- **Deep references**:
  - `docs/design/jila_design_decision_register.md` (UX-D-041, UX-D-032)
  - `docs/ux/jila_design_guide.md` (“Lite Imperative”)

## UX-P-003 — Respect regional trauma & color associations (red caution)

- **Status**: DECIDED
- **Decision (v1)**:
  - Never rely on **bright red** alone to communicate urgency/destruction; always pair with icon + label (UX-P-005).
  - Prefer **terracotta/maroon** for warnings and destructive emphasis where culturally safer; reserve bright red for
    strict “error/failure” semantics.
  - Reserve **true red** for **alerts and failures only** (not “attention”, not “progress”).
- **Deep references**:
  - `docs/design/jila_design_decision_register.md` (UX-D-010 semantic tokens; UX-D-021 redundant encoding)

## UX-P-004 — Optimize for energy (OLED true-black dark)

- **Status**: DECIDED
- **Decision (v1)**:
  - Support an **OLED-friendly true-black** dark mode surface (`#000000`) to reduce battery usage on OLED devices.
  - Avoid “Material Design grey” dark backgrounds such as `#121212` for the primary canvas.
- **Deep references**:
  - `docs/design/jila_design_decision_register.md` (UX-D-010 token mapping guidance)

## UX-P-005 — Double-code colors (color + symbol + text)

- **Status**: DECIDED
- **Decision (v1)**:
  - Color is never the only signal: every status must be communicated via **redundant encoding**:
    - color + icon/symbol + short label (or text).
  - Examples:
    - Error/Failure: red + warning/triangle icon + “Error”
    - Success: green + checkmark + “OK”
- **Deep references**:
  - `docs/design/jila_design_decision_register.md` (UX-D-021; UX-D-046 non-negotiables)

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

## UX-P-011 — No raw error codes to users

- **Status**: DECIDED
- **Decision (v1)**:
  - Never show raw error codes, stack traces, HTTP status codes, or technical messages to end users.
  - All error states must be translated into **human-readable guidance**: icon + short headline + recovery action.
  - Technical details may be logged for debugging but must not surface in the UI.
- **Why it matters**: Raw errors cause panic, erode trust, and provide no actionable path for non-technical users.
- **Deep references**:
  - `docs/design/jila_design_decision_register.md` (UX-D-049 Graceful Missing States)

## UX-P-012 — Last known state is sacred

- **Status**: DECIDED
- **Decision (v1)**:
  - Never hide last-known critical data behind a spinner or blank screen.
  - When refresh fails or data is stale, show the **last known value** with a clear **freshness indicator** (timestamp).
  - This is distinct from loading states (waiting for initial data) — UX-P-012 applies when data existed but cannot be refreshed.
- **Constraints (v1)**:
  - Stale data must be visually differentiated (e.g., "ghosted" or desaturated) but remain legible.
  - Always pair stale data with a timestamp anchor (e.g., "Last updated: HH:MM").
  - Provide a user-driven refresh action rather than endless background retry loops.
- **Why it matters**: Prevents user panic ("Is my tank empty?") and maintains trust under unreliable network conditions.
- **Deep references**:
  - `docs/design/jila_design_decision_register.md` (UX-D-036, UX-D-037)

## UX-P-013 — Respect reduce-motion (accessibility)

- **Status**: DECIDED
- **Decision (v1)**:
  - Respect OS-level **reduce-motion** settings on all platforms (web: `prefers-reduced-motion`; mobile: OS accessibility settings).
  - All animations, transitions, and motion effects must have a **static fallback**.
  - When reduce-motion is enabled: disable tilt interactions, fluid simulations, parallax effects, and auto-playing animations.
- **Why it matters**: Motion sensitivity affects many users (vestibular disorders, motion sickness). This is a WCAG 2.3.3 requirement and a legal accessibility obligation.
- **Deep references**:
  - `docs/design/jila_design_decision_register.md` (UX-D-040 Tank UI constraints)

## UX-P-014 — Instruction by picture, not paragraph

- **Status**: DECIDED
- **Decision (v1)**:
  - For procedural tasks (installation, setup, ordering), prefer **illustration-led** instruction over text-heavy explanations.
  - Illustrations should carry the sequence and meaning with minimal text; text serves as a caption, not the primary carrier of information.
  - This supports non-tech-savvy and linguistically diverse users across literacy levels.
- **Constraints (v1)**:
  - Legal/consent content that must be precise is exempt (use copy-first).
  - Detailed troubleshooting that cannot be reliably conveyed visually is exempt.
- **Why it matters**: Reduces translation burden, increases comprehension across languages/literacy levels, and aligns with the "Blueprints of Life" illustration strategy.
- **Deep references**:
  - `docs/design/jila_design_decision_register.md` (UX-D-032 Illustration strategy)

## UX-P-015 — Never clear input on failure

- **Status**: DECIDED
- **Decision (v1)**:
  - When a form submission or user action fails, **never clear** the user's input.
  - Preserve all entered data and allow the user to correct and retry.
  - This applies to all forms, search fields, and data entry surfaces.
- **Why it matters**: Clearing input on failure punishes the user for system errors, increases frustration, and violates the principle of user-entered data being sacred.
- **Deep references**:
  - `docs/design/jila_design_decision_register.md` (UX-D-020 Forms pattern defaults)

## UX-P-016 — Same concept = same label and icon everywhere

- **Status**: DECIDED
- **Decision (v1)**:
  - A given concept must use the **same label** and the **same icon** across all surfaces and screens.
  - No "same word, different icon" or "same icon, different meaning" drift.
  - This applies to navigation, actions, status indicators, and all semantic UI elements.
- **Why it matters**: Consistency builds a mental model quickly and reduces confusion for all users, especially those with lower digital literacy.
- **Deep references**:
  - `docs/design/jila_design_decision_register.md` (UX-D-048 Consistency doctrine)
  - UX-P-008 (limited semantic palette)
