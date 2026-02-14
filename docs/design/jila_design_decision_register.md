# Jila — Design Decision Register (Anti-ambiguity) (v0.1)

Purpose: track **design-system choices** (tokens, components, iconography, patterns) so UI doesn’t drift across squads/screens.

Principle: once a decision is **DECIDED**, other docs/tickets must reference it and must not re-introduce alternates.

---

## 0) Canonical map (do not drift)
- Canonical design principles (cross-platform): `docs/design/jila_canonical_design_principles.md`
- Decision register index (platform split): `docs/decision_registers/00_index.md`
- Mobile product decisions: `docs/decision_registers/mobile_app_decision_register.md`
- Mobile UX rules (journeys + guardrails): `docs/pm/mobile_app/02_user_journey_maps.md`
- Language/accessibility/UI invariants: `docs/pm/mobile_app/09_localization_and_accessibility.md`
- UI library decision: React Native Paper (see MA-022 in mobile decision register)
- Theme and brand tokens: `docs/design/jila_theme_and_brand_tokens_v1.md`

---

## 1) Ownership and change policy

### UX-D-001 — Ownership model for design decisions
- **Status**: DECIDED
- **Decision (v1)**:
  - **Accountable owner (final decider)**: **PM**.
  - **Expected reviewers**: design + engineering leads review for coherence, feasibility, and drift prevention (PM remains final).
  - **Change bar for DECIDED items**: requires a short rationale + screenshots (where applicable) and must update this register + the design guide in the same change.
- **Why it matters**: without a clear owner/process, design tokens and component patterns will drift quickly.

---

## 2) Foundation tokens (v1)

### UX-D-010 — Color tokens (brand + semantic)
- **Status**: DECIDED
- **Decision (v1)**: Define a single, cross-platform theme and token contract that all product surfaces inherit.
  - **Canonical tokens (v1)**: `docs/design/jila_theme_and_brand_tokens_v1.md` (this is the single source of truth)
  - Platform docs may define derived tokens (hover/alpha/rings), but must not redefine base colors/meanings.
- **Why it matters**: prevents “multiple primaries” and conflicting semantics across mobile + web.

### UX-D-011 — Typography scale
- **Status**: DECIDED
- **Decision (v1)**: Use a consistent “Data vs. Narrative” typography contract across platforms.
  - **Canonical typography (v1)**: `docs/design/jila_theme_and_brand_tokens_v1.md` (Typography section)
- **Why it matters**: preserves brand voice and improves comprehension of readings across surfaces.

### UX-D-051 — Typography roles + weight discipline (cross-platform)
- **Status**: DECIDED
- **Decision (v1)**: Standardize font families and permitted weights across **mobile, web portal, and website**.
  - **Narrative/UI**: **IBM Plex Sans** only.
  - **Data**: **Silka Mono** only.
  - **Allowed weights**:
    - IBM Plex Sans: `400`, `500`, `600`
    - Silka Mono: `400`, `500`
  - **Disallowed**:
    - IBM Plex Sans `300`
    - `700+` weights
    - Casual italics
  - **Usage rules**:
    - Silka Mono is **numbers-only** (no paragraphs).
    - Do not switch fonts between product surfaces and website.
- **Canonical details**: `docs/design/jila_theme_and_brand_tokens_v1.md` (Typography section) and platform specs.
- **Why it matters**: keeps hierarchy clean, improves scanability in dense UIs, and prevents brand fracture.

### UX-D-052 — Typography system spec (numeric + metrics + tracking)
- **Status**: DECIDED
- **Decision (v1)**: Enforce consistent numeric behavior, line-height, letter-spacing, and strict font loading rules.
  - **Tabular numbers** for aligned numeric surfaces (tables, KPIs, dashboards).
  - **Locale-aware formatting** with thousand separators; units use a **thin space**.
  - **Line-height rules** for IBM Plex Sans and Silka Mono (headings ≤ `1.25`).
  - **Letter-spacing rules** (labels/caps/mono density) with **no negative tracking** for mono.
  - **Strict no-fallback**: do not use font fallback stacks; load canonical fonts before render.
- **Canonical details**: `docs/design/jila_theme_and_brand_tokens_v1.md` (Typography section).
- **Why it matters**: ensures data legibility, alignment in dense UIs, and consistent brand rhythm across all surfaces.

### UX-D-012 — Spacing and radius scale
- **Status**: DECIDED
- **Decision (v1)**: Use a single spacing + radius scale across platforms (expressed as dp/px/rem as appropriate).
  - **Canonical spacing/radius (v1)**: `docs/design/jila_theme_and_brand_tokens_v1.md` (Spacing + radius section)
- **Why it matters**: prevents per-platform spacing drift (“feels like a different product”).

### UX-D-046 — Contrast policy + “Solar Mode” (outdoor usability)
- **Status**: DECIDED
- **Decision (v1)**: Design for direct-sunlight use as a first-class accessibility requirement.
  - **Body text** must meet WCAG 2.1 **AAA (≥ 7:1)** contrast ratio.
  - **Primary CTAs** and critical indicators must remain legible in glare; prefer high-contrast pairings as long as they meet contrast requirements (e.g., dark text on a light-teal primary, or light text on a dark-blue secondary).
- **Solar Mode (v1)**: Provide a **High Contrast Light Mode** (black text on white/pale sky surfaces) that can be activated automatically in intense sunlight conditions.
- **Constraints (v1)**:
  - Must be stable (avoid rapid theme flipping; use hysteresis).
  - Must allow user override and respect OS accessibility settings.
  - Must not rely on color alone for meaning (pair with labels/icons).
- **Canonical details**: `docs/ux/jila_design_guide.md` (Contrast & Solar Mode)
- **Why it matters**: ensures usability outdoors where low-contrast “cool grey” UI becomes unreadable.

---

## 3) Component defaults (React Native Paper) (v1)

### UX-D-020 — Forms pattern defaults
- **Status**: DECIDED
- **Decision (v1)**: Standardize all forms using a consistent Paper-friendly pattern to reduce errors for novice users.
- **Pattern (v1)**:
  - Inputs are **outlined** with labels; helper/error text appears directly beneath the field.
  - Validation timing: validate on **blur + submit** (avoid noisy per-keystroke errors).
  - Errors are **field-level** when possible; otherwise one deterministic form-level error.
  - Never clear user input on failure (MA-024).
- **Submission feedback (v1)**:
  - Primary submit shows immediate pressed/loading state.
  - Offline-queueable writes show `Saved offline → Pending sync → Synced/Failed` inline (MA-025, UX-D-021).
- **Canonical details**: `docs/ux/jila_design_guide.md` (Forms)
- **Why it matters**: forms are everywhere (auth, readings, orders) and must feel consistent and trustworthy.

### UX-D-021 — Status indicators (sync + risk)
- **Status**: DECIDED
- **Decision (v1)**:
  - **Sync states** (`Saved offline / Pending sync / Failed`) are always shown **inline** near the affected object/action (never hidden in a toast-only pattern).
  - **Water risk states** (`NORMAL/LOW/CRITICAL`) are expressed via a **redundant signal**: color + icon + short label (per “color is never the only signal”).
  - **Stale/Offline “Last Known State” (Ghost)**: when the latest sensor data can’t be refreshed, show the **last known reading** but visually “ghost” it (desaturated/greyed) while keeping the number readable; pair with a prominent “Last updated” timestamp (see UX-D-036).
- **Why it matters**: trust-critical; users must understand risk and staleness at a glance without panicking.

### UX-D-022 — Navigation affordances
- **Status**: DECIDED
- **Decision (v1)**:
  - **Alerts access** (per MA-029): provide a consistent bell entry in key contexts without adding a 5th tab.
    - Show a bell icon entry on key screens (Home/Orders) and a stable entry row in Profile.
    - Badge rules: show unread count badge when >0 (cap display, e.g., “9+”).
  - **Standard states**: use a consistent set of loading/empty/error components across the app:
    - Loading: prefer skeletons/inline spinners; avoid full-screen “panic spinners” for monitoring (MA-005 / UX-D-036).
    - Empty: illustration-led empty state + one primary CTA (MA-008).
    - Error: diagnostic card from the standard diagnostic gallery (UX-D-039), not raw error codes.
- **Canonical details**: `docs/ux/jila_design_guide.md` (Navigation affordances + standard states)
- **Why it matters**: reduces cognitive load and keeps navigation predictable.

### UX-D-047 — Simple, flat navigation + one-primary-action screens
- **Status**: DECIDED
- **Decision (v1)**: Optimize for novice users with a simple, linear interaction model:
  - Prefer **single-column** screen layouts for primary flows.
  - Each screen has **one clear primary task/action**; secondary actions are de-emphasized.
  - Prefer **step-by-step (wizard-like)** progression for complex tasks over hub-and-spoke menus.
  - Avoid deep hierarchies and dense menus; prefer large buttons/cards for options.
- **Canonical details**: `docs/ux/jila_design_guide.md` (Navigation & screen structure)
- **Why it matters**: reduces cognitive load and error rate for low digital literacy users.

### UX-D-048 — Consistency & predictability doctrine (ruthless simplicity)
- **Status**: DECIDED
- **Decision (v1)**: Make the app highly predictable by reusing standard mobile patterns and repeating placement/meaning:
  - A tap always yields **immediate visible feedback** (pressed state, color change, checkmark/progress) so users learn what to expect.
  - **Consistent iconography**: the same symbol means the same concept everywhere (no “same word, different icon” drift).
  - **Stable navigation placement**: key navigation stays in consistent locations (e.g., persistent bottom navigation where applicable).
- **Constraints (v1)**:
  - Feedback must not rely on sound alone; respect OS settings.
  - Prefer fewer patterns, reused everywhere, over bespoke UI per screen.
- **Canonical details**: `docs/ux/jila_design_guide.md` (Consistency & feedback rules)
- **Why it matters**: builds a mental model quickly, increasing confidence and reducing drop-off due to confusion.

---

## 4) Iconography and imagery (v1)

### UX-D-030 — Icon set and usage rules
- **Status**: DECIDED
- **Decision (v1)**:
  - Default icon set: **Material Community Icons** (via `react-native-vector-icons/MaterialCommunityIcons`).
  - Follow icon style/state rules already DECIDED:
    - Semi-abstract iconography (UX-D-044)
    - Solid active / outline inactive (UX-D-045)
- **Rules (v1)**:
  - For navigation icons, only choose glyphs that have a clear **filled + outline** pair (commonly `name` + `name-outline`).
  - If a concept lacks a good pair in MCI, prefer:
    - picking a different MCI glyph that does have a pair, or
    - using a **custom SVG** in our semi-abstract line-art style with both outline/filled variants (aligns with UX-D-041 vector-first).
  - Critical/money actions must be icon+label (do not rely on icon alone).
- **Why it matters**: accessibility and clarity for low-literacy + high-stress scenarios (orders, critical alerts).

### UX-D-044 — Semi-abstract iconography (line art) over photoreal or abstract
- **Status**: DECIDED
- **Decision (v1)**: Default iconography is **semi-abstract**: simplified **line drawings** that preserve the essential silhouette of real-world objects.
- **Rationale (v1)**:
  - Avoid **photorealism**: photos of region-specific artifacts (currency, documents, vehicles) introduce “noise” and can confuse users across markets.
  - Avoid **pure abstraction**: metaphor icons that require “computer literacy” (e.g., gear for Settings) are often unintelligible for novice users.
  - Semi-abstract line art has higher recognition while matching the “Blueprints of Life” technical aesthetic.
- **Rules (v1)**:
  - Prefer **generic object forms** (e.g., generic banknote for “money”) over culturally specific variants.
  - Icons must remain recognizable at small sizes and in bright sunlight; test at minimum tab/icon sizes.
- **Canonical details**: `docs/ux/jila_design_guide.md` (Iconography rules)
- **Why it matters**: reduces translation load and improves recognition for low-literacy users across regions.

### UX-D-045 — Hybrid icon states: solid active, outline inactive
- **Status**: DECIDED
- **Decision (v1)**: Use **solid (filled) icons** for the **active/selected** navigation state and **outline icons** for the **inactive** state.
- **Rules (v1)**:
  - Maintain the same base glyph/silhouette between outline and solid variants (state change should not change meaning).
  - Active state must also include a redundant cue (label style/color) so color alone is not the only signal.
- **Why it matters**: improves recognition speed and state clarity (especially outdoors and for lower visual acuity).

### UX-D-032 — Illustration strategy (“Blueprints of Life”)
- **Status**: DECIDED
- **Decision (v1)**: Replace text-heavy instruction with **isometric technical illustrations** (“Blueprints of Life”) to support non-tech-savvy and linguistically diverse users.
  - **Ikea/Dyson manual style**: step-by-step **white-line drawings** on **midnight navy** background for procedural tasks (install sensor, order water).
  - **X-ray / cutaway vision**: for tank/sensor education, use **cutaway** (“x-ray”) illustrations that clearly show the sensor positioned inside the tank.
  - **Contextual backgrounds (Industrial Afrofuturism)**: use subtle, semi-abstract **background line art** that depicts the user’s environment (rural homestead / urban roof) to ground high-tech data in local reality.
- **Rules (v1)**:
  - **Primary goal**: comprehension without reading; keep captions minimal and localization-light.
  - **Consistency**: one illustration language across onboarding, help, and complex flows (no mixing photoreal 3D with line art in the same flow).
  - **Accessibility**: illustrations must not be the only carrier of meaning; pair with icons + minimal labels where required for safety-critical actions.
- **Canonical details**: `docs/ux/jila_design_guide.md` (Illustration Strategy section)
- **Why it matters**: reduces language dependence, increases install/order success, and reinforces “visible engineering” trust.

### UX-D-033 — Replenishment Card pattern (low-water → order)
- **Status**: DECIDED
- **Decision (v1)**: When low-water threshold is reached (MA-004), use a **bottom-sheet style Replenishment Card** that:
  - Presents a **single primary CTA** (“Order refill”) with an optional secondary action (dismiss / “See options”).
  - Shows **suggested volume** prominently (numeric in “data voice”) and keeps supporting copy minimal.
  - Uses a **vehicle illustration** that matches the “Blueprints of Life” technical line-art aesthetic (see UX-D-034).
- **Constraints (v1)**:
  - The pattern must remain **non-blocking** (dismissible) and must not hijack navigation.
  - The CTA must route to a **prefilled confirmation** surface (price visible before final confirm), not a catalog.
- **Canonical details**: `docs/ux/jila_design_guide.md` (Replenishment as a Service UI)
- **Why it matters**: reduces decision fatigue in urgent moments while preserving transparency.

### UX-D-034 — Delivery vehicle illustrations (technical line art)
- **Status**: DECIDED
- **Decision (v1)**: Use **accurate technical line art** for specific vehicle types (e.g., “tuk-tuk tanker”, “7-ton truck”), not generic truck icons, wherever the vehicle is part of the delivery promise (replenishment card, order confirmation, tracking, receipts).
- **Style rules (v1)**:
  - Must match the “Blueprints of Life” language: **white-line drawings** on dark surfaces; consistent line weight and callout style.
  - Vehicle type labels are short and localization-safe (avoid slang); the illustration must be recognizable without reading.
- **Why it matters**: helps users identify the arriving vehicle and increases trust via “visible engineering.”

### UX-D-035 — Driver identity presentation (“ID badge” card)
- **Status**: DECIDED
- **Decision (v1)**: In delivery/tracking contexts, display driver identity in a **physical ID-badge style card** with:
  - **Driver photo** and **name** as the primary elements.
  - Supporting metadata secondary (e.g., vehicle type, plate/ID when available), never replacing the photo+name.
- **Why it matters**: builds accountability and reduces anxiety in low-trust delivery environments (Uber/SafeBoda pattern).

### UX-D-036 — Offline-first “Last Known State” (Ghost) for monitoring
- **Status**: DECIDED
- **Decision (v1)**: Monitoring screens must never “blank out” into a spinner when connectivity is unstable. If live refresh fails, the UI shows:
  - The **last known water level** in a **ghosted** visual state (desaturated / greyed), not hidden.
  - A **timestamp anchor** next to the tank: “Last updated: HH:MM” in **Silka Mono** (data voice).
- **Why it matters**: prevents panic (“Is my tank empty?”) and reinforces trust via visible freshness.

### UX-D-037 — Mechanical reconnection control + diagnostic illustrations
- **Status**: DECIDED
- **Decision (v1)**: Replace “endless background retry + spinner” with an explicit, physical-feeling **Refresh** control:
  - User triggers refresh via a button/pull control; on trigger, provide **haptic feedback** (vibration) to simulate a mechanical attempt.
  - On failure, show a **specific illustrated diagnostic** in the “Blueprints of Life” line-art language (e.g., radio tower with a cross), not a generic error code.
- **Why it matters**: restores user agency under unreliable networks and makes failure understandable without reading.

### UX-D-038 — Sensor health surfaced on the main dashboard (battery + signal)
- **Status**: DECIDED
- **Decision (v1)**: Battery life and signal strength are part of the **main monitoring dashboard**, not buried in settings.
  - Use simple, fuel-gauge-like **bar indicators** with clear labels in **Silka Mono** (data voice).
  - Health indicators must remain meaningful in offline mode (e.g., show last known values with timestamps if needed).
- **Why it matters**: reduces IoT mistrust and prevents “silent battery death” surprises.

### UX-D-039 — Standard diagnostic illustration set (offline + device health)
- **Status**: DECIDED
- **Decision (v1)**: Use a small, consistent set of **illustrated diagnostics** (Blueprints of Life line art) for common monitoring failures, instead of generic spinners/toasts/error codes.
- **Standard set (v1)**:
  - **Network down**: radio tower with a cross.
  - **Sensor unreachable** (device offline): sensor icon with broken link / unplug motif. 
  - **Low battery**: battery outline with a warning mark.
  - **Stale reading**: clock/time badge with a warning mark (used when data is old, even if network is fine).
  - **Permission / Bluetooth required** (only if needed by the flow): lock/permission badge + the relevant symbol.
- **Copy rules (v1)**:
  - One short headline + one short guidance line; no paragraphs.
  - Always provide a primary action (e.g., **Refresh**, **See tips**, **Enable**).
  - Never show raw error codes to the user.
- **Canonical details**: `docs/ux/jila_design_guide.md` (Diagnostic gallery)
- **Why it matters**: reduces panic, improves comprehension across languages, and keeps troubleshooting consistent.

### UX-D-040 — “Fluid Reality” tank UI doctrine (digital twin)
- **Status**: DECIDED
- **Decision (v1)**: The primary monitoring visualization is a **skeuomorphic technical tank “digital twin”** that makes invisible sensor data feel physical and engineered.
  - **Viscous fluid simulation**: the tank shows a subtle “water” surface/flow; when the user tilts the phone, the fluid responds (cognitive anchor for low-literacy users).
  - **Glass & steel container**: use a high-end **industrial gauge** aesthetic (glass + iron/nickel metallic finish), avoiding cartoon-flat blue shapes.
- **Constraints (v1)**:
  - **Accessibility + truth**: the numeric reading and freshness must remain present (Silka Mono + “Last updated”); the visual can’t be the only carrier of meaning.
  - **Reduced motion**: respect OS “reduce motion” settings; provide a static fallback (no tilt, no simulation).
  - **Performance**: degrade gracefully on low-end devices (simpler animation or static render); never drop frames so badly that it harms comprehension.
  - **Offline-first**: in offline/ghost state, the tank remains visible with ghosting + timestamp (UX-D-036).
- **Canonical details**: `docs/ux/jila_design_guide.md` (Tank UI — Fluid Reality)
- **Why it matters**: bridges digital-to-physical understanding and signals “engineered precision,” increasing trust in IoT readings.

### UX-D-041 — “Lite Imperative” (Infrastructure as UX)
- **Status**: DECIDED
- **Decision (v1)**: Treat data cost, storage, and low-end device performance as **primary UX constraints**. The app must remain usable on older Android devices and unstable/slow networks.
- **Vector-first strategy (v1)**:
  - Prefer **SVG/vector** assets (line art, icons, diagnostics) over raster imagery wherever possible.
  - The “Blueprints of Life” illustration language is a **performance strategy** as well as an aesthetic: instructional visuals must be deliverable with minimal bytes.
- **Constraints (v1)**:
  - Avoid heavy image/video backgrounds and large raster “hero” assets in core flows.
  - Animations must degrade gracefully (tilt/fluids/particles must have a static fallback; respect Reduce Motion).
  - Maps/visualizations should prefer lightweight rendering and avoid unnecessary layers/overdraw.
- **Canonical details**: `docs/ux/jila_design_guide.md` (Lite guardrails)
- **Why it matters**: prevents churn caused by slow loads, high data usage, and poor performance on 2015-class devices.

### UX-D-042 — Visual weight communicates stability (low-trust markets)
- **Status**: DECIDED
- **Decision (v1)**: Prefer a **solid, industrial, “engineered”** UI posture over thin/hairline/airy minimalism to convey robustness and stability.
- **Rules (v1)**:
  - Avoid hairline type and ultra-light strokes for primary UI (especially on Android low-end displays).
  - Prefer clear visual hierarchy with **substantial containers**, visible dividers, and “machined” edges where appropriate (consistent with the Dyson-inspired language).
  - Density should feel intentional: enough whitespace for readability, but not so airy that screens feel empty/ephemeral.
- **Canonical details**: `docs/ux/jila_design_guide.md` (Trust & stability visual posture)
- **Why it matters**: in low-trust environments, perceived stability reduces anxiety and increases completion rates for money/ordering flows.

### UX-D-043 — Tangible feedback loops (haptics + optional mechanical sound)
- **Status**: DECIDED
- **Decision (v1)**: Every user action that changes state (especially money/order actions) must produce an **immediate, tangible confirmation** via haptics and (where appropriate) optional mechanical sound cues.
- **Rules (v1)**:
  - Use **haptic feedback** for primary actions and critical state transitions (submit, confirm, accept, retry).
  - Mechanical sound effects (e.g., “click/thud”) are **allowed** as reinforcement but must:
    - Respect OS mute/silent settings and accessibility preferences.
    - Never be the only confirmation (haptics/visual state must still confirm).
    - Be used sparingly (avoid noisy, spammy feedback).
- **Canonical details**: `docs/ux/jila_design_guide.md` (Feedback policy)
- **Why it matters**: replaces uncertainty with “machine certainty,” increasing trust and reducing abandonment.

### UX-D-031 — Map markers and legend style
- **Status**: DECIDED
- **Decision (v1)**: Use simple, high-contrast, lightweight markers that communicate status with redundant signals (color + icon + label) and a minimal legend/filters.
- **Marker rules (v1)**:
  - Marker encodes:
    - **Type** (SupplyPoint vs Seller listing) via icon silhouette.
    - **Status** via semantic color (with an icon/label fallback so color isn’t the only signal).
    - **Freshness** is visible on detail and surfaced in legend copy (timestamp), not as dense on-marker text.
  - Markers must remain legible in sunlight (AAA posture) and small screens; avoid thin outlines.
- **Legend + filters (v1)**:
  - Provide a small legend and 2–4 simple filters (chips) in a bottom sheet (vector-first, low overdraw).
  - Avoid heavy overlays and excessive layers (UX-D-041).
- **Canonical details**: `docs/ux/jila_design_guide.md` (Map markers)
- **Why it matters**: map is a primary entry path; poor marker semantics breaks discovery trust.

---

## 5) Decisions log (template)

Use this template for new entries:
- **Status**: OPEN | DECIDED
- **Decision needed / Decision**
- **Why it matters**

---

## 6) Graceful missing states (cross-platform) (v1)

### UX-D-049 — Graceful missing states (loading / empty / error)
- **Status**: DECIDED
- **Decision (v1)**: Define a consistent set of missing-state patterns that apply across all platforms.
- **Loading states (v1)**:
  - Use **skeletons** for lists, cards, and content areas (not full-screen spinners).
  - Use **inline spinners** for action buttons and small loading indicators.
  - **Never** blank critical data (monitoring screens) into a spinner-only view — show last known state instead (UX-P-012).
- **Empty states (v1)**:
  - Every empty state must include: illustration/icon + headline + guidance text + one primary CTA.
  - No blank screens; always explain what to do next.
- **Error states (v1)**:
  - Use inline `Alert` with icon + human-readable message + recovery action.
  - Never show raw error codes, stack traces, or HTTP status codes (UX-P-011).
  - Prefer stable, persistent diagnostic cards over toast-only patterns for recoverable errors.
- **In-progress/async states (v1)**:
  - Show immediate feedback on async actions: disabled state + progress indicator.
  - Prevent double-submit by disabling the action while in progress.
- **Canonical details**: `docs/ux/jila_design_guide.md` (Standard states in Navigation affordances)
- **Why it matters**: Consistent missing-state patterns reduce user confusion and build trust across all product surfaces.

### UX-D-050 — Design token consolidation (v1.1 update)
- **Status**: DECIDED
- **Decision (v1.1)**: Extend the canonical token contract with the following additions:
  - **Typography variants**: Define `kpi` (32px/500) and `reading` (24px/400) as canonical mono-font variants for data display across all platforms.
  - **Spacing naming**: Standardize on `xs=4, sm=8, md=12, base=16, lg=24, xl=32, 2xl=48` — using `base` (not `lg`) for the 16px foundational unit.
  - **onPrimary contrast**: Add explicit `onPrimary: #000000` to canonical palette for AAA contrast on teal.
  - **Glass effect**: Standardize glass surface parameters cross-platform: alpha `0.70`, blur `12px` (panels) / `24px` (modals), border `rgba(255,255,255,0.08)`.
- **Alternatives considered**:
  - Intent-only typography variants (rejected: exact values prevent drift)
  - Keeping `lg=16` naming (rejected: `base` is clearer as foundational unit)
  - Platform-specific glass effects (rejected: consistent elevated-surface treatment benefits both platforms)
- **Canonical details**: `docs/design/jila_theme_and_brand_tokens_v1.md` (Sections 2.1, 3.1, 5.1)
- **Why it matters**: Ensures visual consistency between web and mobile for data displays, spacing, and elevated surfaces while preventing per-platform drift.
