---
title: Jila — Design Guide
status: Draft (v0.1)
scope: Mobile app (v1) — implementation guidance for DECIDED design decisions
last_updated: 2026-01-14
---

## Purpose
This document turns **DECIDED** items from the design decision register into **mobile-specific implementable guidance**
so the UI doesn't drift across screens/squads.

## Scope note (important)
This guide is scoped to **mobile app implementation details**. Cross-platform universal principles have been extracted
to the canonical principles document (`docs/design/jila_canonical_design_principles.md`).

**What lives here**: Mobile-specific patterns, React Native Paper theming, haptic/sound feedback, illustration placement
guidance, and component-level implementation details.

**What lives in canonical principles**: Universal truths that apply across web and mobile (contrast, color encoding,
reduce-motion, "never clear input on failure", etc.). Always reference canonical principles; do not restate alternates here.

## Canonical references (do not drift)
- Canonical design principles (cross-platform): `docs/design/jila_canonical_design_principles.md` (UX-P-001..016)
- Design decision register (design system): `docs/design/jila_design_decision_register.md`
- Mobile app decision register (product): `docs/decision_registers/mobile_app_decision_register.md`
- Inclusive design addendum: `docs/pm/mobile_app/10_inclusive_design_guidelines.md`
- Theme and brand tokens (cross-platform): `docs/design/jila_theme_and_brand_tokens_v1.md`

---

## Global non-negotiables (cross-references to canonical principles)

These rules are defined in `docs/design/jila_canonical_design_principles.md` and apply across all platforms.
Reference the canonical principle; do not restate alternates here.

- **Outdoor-first contrast**: body text must meet WCAG AAA; Solar Mode exists for sunlight → **UX-P-001**
- **Color is never the only signal**: pair meaning with icon/shape + label → **UX-P-005**
- **No raw error codes** in user-facing UI: use stable diagnostics with one action → **UX-P-011**
- **Last known state is sacred**: never blank critical monitoring into spinner-only; keep last known reading + timestamp → **UX-P-012**
- **Respect reduce-motion**: all animations must have static fallback → **UX-P-013**
- **Instruction by picture, not paragraph**: prefer illustration-led guidance for procedures → **UX-P-014**
- **Never clear input on failure**: preserve user-entered data on errors → **UX-P-015**
- **Same concept = same label/icon everywhere**: no "same word, different icon" drift → **UX-P-016**
- **Industrial stability over fragility**: clear containers, visible edges, pressable controls; avoid hairlines → **UX-P-009**

---

## Typography usage (mobile) (UX-D-051)
**Intent:** Keep mobile typography legible, calm, and predictable with strict weight discipline.

### IBM Plex Sans (Narrative/UI)
- **Body text**: `400` (default reading weight)
- **Secondary text / hints**: `400` (use opacity/size, not lighter weight)
- **Labels (inputs, switches)**: `500`
- **Section titles**: `600` (short, not paragraph-length)
- **Buttons (primary & secondary)**: `500` (avoid bold buttons)

### Silka Mono (Data)
- **Key metrics** (tank level, usage): `500`
- **Inline numeric values**: `400`
- **Timestamps / IDs**: `400`

### Rules
- Never use Silka Mono for paragraphs; numbers only.
- Do not use IBM Plex Sans `300` or `700+` weights.
- Avoid italics unless explicitly required.
- Do not rely on fallback fonts; bundle IBM Plex Sans and Silka Mono.
- Use **tabular numbers** for aligned numeric UI (tables, KPIs, dashboards).
- Format numbers locale-aware with thousand separators; units use a **thin space** (`12.4 L`, `3 m³`, `85 %`).
- **Line-height**: headings ≤ `1.25`; body `1.45–1.5`; labels `1.3–1.4`; mono tables `1.35–1.4`; mono KPIs `1.2–1.3`.
- **Letter-spacing**: labels `+0.01em`; all-caps `+0.04–0.06em`; mono dense `+0.02em`; mono small `+0.03em`; never negative tracking for mono.

---

## Illustration Strategy — “Blueprints of Life” (UX-D-032)
**Intent:** Replace text-heavy instructions with an illustration language that teaches through visuals for non-tech-savvy, linguistically diverse users.

### Design principles
- **Instruction by picture, not paragraph**: illustrations should carry the sequence and meaning with minimal text.
- **Visible engineering**: show how the system works (especially the sensor-in-tank relationship) to build trust.
- **Local reality, not generic tech**: ground illustrations in recognizable environments via subtle contextual line art.

### Core illustration styles (v1)
- **Ikea/Dyson manual style (procedures)**:
  - Use **step-by-step white-line drawings** on a **midnight navy** background.
  - Use numbered steps and arrows; keep labels short and avoid idioms.
  - Preferred for: install sensor, pair device, basic troubleshooting, order water flow explanations.

- **X-ray / cutaway vision (education)**:
  - Use **cutaway** (“x-ray”) illustrations when depicting tanks/reservoirs.
  - Clearly show the **sensor inside the tank** and what it measures.
  - Preferred for: “How it works” screens, calibration/setup explanations, trust-building tooltips.

- **Contextual backgrounds (Industrial Afrofuturism)**:
  - Add subtle, semi-abstract **background line art** that suggests context (rural homestead, urban roof).
  - Keep it low-contrast and non-distracting; it should never compete with primary UI content.
  - Preferred for: onboarding/help headers, empty states, learning moments.

### When to use illustrations vs. copy (decision rules)
- **Use illustration-first** when:
  - The user must complete a real-world action (installation, placement, ordering steps).
  - The concept is technical and likely unfamiliar (sensor, telemetry, calibration).
  - The flow must work across languages and literacy levels.
- **Use copy-first** when:
  - The content is legal/consent-related or must be precise (policies, permissions explanations).
  - The user needs detailed troubleshooting steps that cannot be reliably conveyed visually.

### Content rules (must-haves)
- **Minimal text**: captions are allowed but must be short and localization-safe.
- **Do not rely on color alone**: see **Global non-negotiables** (UX-P-005).
- **One visual grammar**: arrows, callouts, step numbers, and line weights should be consistent across the app.
- **Cultural appropriateness**: avoid stereotypes; keep motifs subtle (UX-P-002).

### Don’ts (anti-drift)
- **No photorealism** for instructional sequences in v1 (avoid mixed metaphors and higher asset cost).
- **No dense annotated diagrams** that become text-heavy via labels.
- **No background clutter**: contextual line art must remain subtle and secondary.

### Example application mapping (v1)
- **Install sensor**: manual-style steps + cutaway final frame showing correct in-tank placement.
- **Order water**: manual-style sequence showing selection → confirmation → delivery expectation.
- **Tank status screen education**: cutaway illustration used as an explainer (tap “How it works”).
- **Empty/first-run states**: contextual background line art + a simple isometric object scene.

---

## Offline-first Monitoring UI — “Last Known State” (UX-D-036 / UX-D-037)
**Intent:** Prevent panic under unstable connectivity by keeping the last known data visible, clearly marked as stale, and giving the user agency to retry.

### “Ghost” treatment (Last Known State)
- Never blank the dashboard into a full-screen spinner-only view when refresh fails (see **Global non-negotiables**).
- **Keep the last known water level visible** but apply a “ghost” treatment:
  - Desaturate the primary water fill/accent (e.g., cyan → grey).
  - Reduce emphasis on decorative elements, but keep the numeric reading high-contrast and readable.
- **Pair ghosting with an explicit freshness anchor** (see next section). Ghosting without a timestamp is not allowed.

### Timestamp anchor (“Last updated”)
- Place a prominent timestamp near the primary reading/tank graphic:
  - Format: `Last updated: HH:MM` (localized time formatting; keep copy minimal).
  - Typography: **Silka Mono** (data voice) per UX-D-011.
- If the timestamp is unknown (e.g., first-ever load failed), show a clear “No reading yet” empty state (do not show fake zeros).

### Mechanical reconnection (Refresh control + haptics)
- Prefer an explicit **Refresh** control (button or pull action) that feels physical:
  - On trigger, provide **haptic feedback** (short vibration) to simulate a “connection attempt.”
  - Keep the in-place UI stable during refresh; avoid full-screen blocking loaders.
- **Retry semantics (v1)**:
  - Refresh attempts are user-driven (plus safe refresh on app foreground); avoid endless background spinner loops.
  - On repeated failures, do not spam toasts—show a stable diagnostic card (next section).

### Diagnostic cards (no generic error codes)
- On refresh failure, show a **specific diagnostic card** using the “Blueprints of Life” line-art language:
  - Example: radio tower icon/line drawing with a cross for “No signal / network.”
  - Include one short, controlled sentence of copy (localized) and an obvious next action:
    - e.g., “No connection. Try again.” + **Refresh** CTA
    - Optional secondary: “See tips” linking to a short illustrated help panel (not paragraphs).
- Use the canonical diagnostic format (UX-D-039).

---

## Sensor Health on Dashboard — Battery & Signal (UX-D-038)
**Intent:** Reduce IoT mistrust by making device health visible, legible, and explainable without digging into settings.

### What is always visible (v1)
- **Battery** and **signal strength** appear on the main monitoring/dashboard surface alongside the primary reading.
- Use simple **bar gauges** (fuel-gauge style) that can be understood without reading.

### Labeling and typography
- Labels and values use **Silka Mono** (data voice) where they are “meter-like”:
  - `Battery` + value (e.g., `75%`)
  - `Signal` + simple level (bars) or value if available
- Keep labels short and consistent with controlled vocabulary rules.

### Offline/stale behavior
- If health values are stale/unrefreshable, apply the same **Last Known State** pattern as the main reading (UX-D-036).
- Never hide health indicators just because the network is down; hiding increases anxiety.

---

## Diagnostic gallery — Standard illustrated states (UX-D-039)
**Intent:** Make failures understandable without reading long text, using a consistent “Blueprints of Life” illustration language.

### Format (every diagnostic card)
- **Illustration** (line art) + **Headline** (short) + **Guidance** (one short line) + **Primary action**.
- Headline/guidance must be localization-safe (no idioms, no paragraphs).
- Never show raw error codes to users (see **Global non-negotiables**).

### Standard set (v1)
| Condition | Illustration metaphor | Headline (example) | Primary action | Optional secondary |
|---|---|---|---|---|
| Network down | Radio tower with a cross | “No connection” | **Refresh** | “See tips” |
| Sensor unreachable (device offline) | Sensor with broken link/unplug motif | “Sensor offline” | **Refresh** | “See tips” |
| Low sensor battery | Battery outline with warning mark | “Low battery” | **See steps** | “Dismiss” |
| Stale reading | Clock/time badge with warning mark | “Data is old” | **Refresh** | “See tips” |
| Permission required (only when needed) | Permission/lock badge + relevant symbol | “Permission needed” | **Enable** | “Not now” |

### Copy guidance (examples)
- **No connection**: “Showing last known data.” (keeps user calm + reinforces Last Known State)
- **Sensor offline**: “Check the sensor is on.” (short, no jargon)
- **Low battery**: “Replace/charge soon.” (actionable, short)
- **Data is old**: “Last updated at HH:MM.” (ties to timestamp anchor)

### Integration rules
- Diagnostic cards always respect the **Last Known State** pattern:
  - Keep last data visible (ghosted) and show freshness; the card explains why refresh isn’t updating.
- Prefer stable, persistent diagnostic cards over toast spam for repeated failures.

---

## Tank UI doctrine — “Fluid Reality” (UX-D-040)
**Intent:** Make sensor readings feel physical and “engineered” by turning the tank into a digital twin users can intuitively understand.

### What the tank visualization must communicate (v1)
- **Current fill level** (visually + numerically).
- **Freshness** (“Last updated”) and **Ghost** treatment (Last Known State) when stale/offline (per UX-D-036).
- **Device health glance**: battery + signal remain visible nearby (UX-D-038).

### Must-have UI elements (non-negotiable)
- **Numeric level** (e.g., `45%`) in **Silka Mono** (data voice).
- **Volume** (liters) when available (also Silka Mono).
- **Timestamp anchor**: “Last updated: HH:MM” near the tank (Silka Mono).
- The tank visualization must never be the only carrier of truth; the numbers are canonical.

### Fluid simulation + tilt interaction
- Use a subtle **viscous water surface** animation inside the tank (no cartoon waves).
- Device tilt changes the surface angle slightly (cognitive anchor), but:
  - The interaction must be **gentle** and never distort the perceived fill level.
  - Keep motion low-amplitude to avoid nausea and misinterpretation.

### Accessibility and motion constraints
- Respect OS **Reduce Motion**:
  - If enabled, disable tilt and fluid animation; show a static, high-contrast fill render.
- Provide an in-app setting if needed later, but OS setting is the minimum requirement.

### Offline behavior (Last Known State)
- When in Last Known State, keep the tank visible and apply the **Ghost** treatment (UX-D-036). If action is needed,
  show a diagnostic card (UX-D-039).

### “Glass & steel” material language (visual rules)
- Avoid flat/cartoon blue fills.
- Use an industrial gauge feel:
  - **Glass**: subtle highlights/reflections (not glossy toy-like).
  - **Metal**: iron/nickel finish cues (cool greys, engineered edges).
- Keep the look consistent with “Blueprints of Life”:
  - The tank can be richer than pure line art, but should still feel technical, not playful.

### Performance and fallbacks
- Default to a performant implementation:
  - Prefer a simple masked fill + lightweight animation over heavy particle sims.
  - If a gradient is used inside the tank fill, it must be explicit and tested on low-end devices; do not use subtle
    gradients for primary UI surfaces (canonical: UX-P-006).
- On low-end devices (or when frame rate drops):
  - Disable tilt first, then simplify the fluid animation, then fall back to static.
- The UX priority is comprehension and stability, not “maximum realism.”

---

## “Lite Imperative” guardrails — Data + performance as UX (UX-D-041)
**Intent:** Ensure Jila works on high data-cost networks and older Android devices by making “lightweight by default” an explicit design constraint.

### Asset strategy (vector-first)
- Prefer **SVG/vector** for:
  - icons, diagnostics, technical illustrations, vehicle illustrations, simple gauges
- Avoid large raster assets in core flows:
  - no full-bleed photos, no heavy image/video backgrounds on primary screens
- If a raster image is unavoidable (rare):
  - keep it small, compressed, and non-blocking (never required to understand the screen)

### Illustration as performance
- “Blueprints of Life” is a **byte budget** choice:
  - instructional sequences should be deliverable as line art + minimal text
- Background line art must remain subtle and lightweight; do not introduce dense textures.

### Motion and rendering budgets (practical rules)
- Any animation-heavy feature must have a **fallback ladder**:
  - full effect → simplified → static
- Respect **Reduce Motion** as a hard constraint:
  - disable tilt/simulation and use static, high-contrast states.
- Avoid UI that depends on continuous network polling to “feel alive.”

### Maps and heavy surfaces
- Treat maps as a high-cost surface:
  - keep overlays minimal; prefer simple markers and avoid unnecessary layers
  - avoid heavy custom tile styles that increase bandwidth unless they are cached and justified

### Offline-first synergy
- Lightweight doesn’t mean “less trustworthy”:
  - always show **last known state + timestamp** and avoid panic spinners (MA-005 / UX-D-036).

---

## Contrast & “Solar Mode” (outdoor accessibility) (UX-D-046)
**Intent:** Keep the app readable outdoors in direct sunlight by enforcing high contrast and providing a high-contrast light theme when needed.

Canonical principles: `docs/design/jila_canonical_design_principles.md` (UX-P-001, UX-P-005)

### Contrast rules (v1)
- **Body text** must meet WCAG 2.1 **AAA (≥ 7:1)**.
- Do not use “cool grey on white” for body text; it becomes invisible in glare.
- Primary CTAs must remain legible in glare; high-contrast pairings are preferred, but must still pass contrast checks (e.g., dark text on a light-teal primary, or light text on a dark-blue secondary).

### Solar Mode (High Contrast Light Mode)
- Provide a theme variant optimized for sunlight:
  - black text on white/pale sky surfaces
  - simplified color palette (contrast first)
- **Auto-switching** (allowed):
  - may use ambient light sensor to enable Solar Mode in intense sunlight
  - must be stable (hysteresis) to prevent flicker while moving between shade/sun
- **User control** (required):
  - allow manual override (on/off/auto)
  - respect OS accessibility preferences (including high-contrast/reduce motion where applicable)

### Non-negotiables
- Solar Mode must not rely on color alone for meaning (icons/labels still required).
- Do not introduce heavy animations during theme switches; keep transitions instant/subtle to avoid confusion.

---

## Theme tokens (React Native Paper alignment) (UX-D-010 / UX-D-046 / UX-D-041)
**Intent:** Make the design system implementable with React Native Paper (MD3) while preserving our contrast, Solar Mode, and “Lite” constraints.

### Token mapping guidance
- Use React Native Paper MD3 theme slots as the implementation surface:
  - `primary`, `secondary`, `background`, `surface`, `error`, `outline`, plus `onPrimary`/`onSurface` for readable text.
- **AAA body text** requirement applies to the effective rendered color pairs, not just token names.

### Primary button rule (glare-safe)
- When `primary` is a **light teal**, prefer a **dark `onPrimary`** to hit AAA contrast outdoors.
- When using a **dark-blue** button surface (e.g., `secondary`), prefer a **light `onPrimary`** to hit AAA contrast outdoors.

### Icon/library note
- Material Community Icons is the default icon set (UX-D-030), but do not block on library gaps:
  - for outline/filled pairing, use alternate MCI glyphs or custom SVG pairs (vector-first).

---

## Layout scale (spacing + radius) (UX-D-012)
**Intent:** Keep spacing and corner radii consistent so screens feel “engineered” and predictable.

### Spacing scale (dp)
- `xs=4`, `sm=8`, `md=12`, `lg=16`, `xl=24`, `2xl=32`, `3xl=48`
- Use these values for padding/margins/gaps; avoid ad-hoc values.

### Radius scale (dp)
- `sm=8`, `md=12`, `lg=16`
- Defaults:
  - Cards: `md`
  - Buttons: `md`
  - Dialogs / bottom sheets: `lg`

---

## Forms (React Native Paper defaults) (UX-D-020)
**Intent:** Make every form feel the same so novice users learn once and succeed everywhere.

### Field style
- Use **outlined** text inputs with clear labels.
- Helper/error text appears directly below the field.

### Validation timing
- Validate on **blur + submit** (avoid noisy per-keystroke errors).
- Prefer mapping backend validation to **field-level** messages when possible.

### Submission + failure behavior
- Never clear input on failures.
- Always show an immediate pressed/loading state on the primary CTA.
- For offline-queueable writes, show inline state: `Saved offline → Pending sync → Synced/Failed`.

---

## Navigation affordances + standard states (UX-D-022)
**Intent:** Make the app predictable by keeping entry points and system states consistent.

### Alerts entry (per MA-029)
- Provide stable access to Alerts without adding a new tab:
  - Bell icon entry on key screens (Home/Orders)
  - Alerts row in Profile
- Show an unread badge when applicable (cap display, e.g., “9+”).

### Standard loading / empty / error states
- **Loading**:
  - Prefer skeletons for lists/cards; use small inline spinners.
  - Avoid full-screen spinners on monitoring screens (MA-005 / UX-D-036).
- **Empty**:
  - Illustration-led empty state + one primary CTA; no blank screens.
- **Error**:
  - Use diagnostic cards from the gallery (UX-D-039); no raw error codes.

---

## Map markers + legend (UX-D-031)
**Intent:** Keep map discovery lightweight and legible while communicating trust signals clearly.

### Marker encoding (redundant signals)
- Encode **type** (SupplyPoint vs Seller) via icon silhouette.
- Encode **status** via semantic color + icon/label backup (never color-only).
- Keep on-marker text minimal; show details (including timestamps/evidence) in the detail sheet.

### Legend + filters
- Use a compact bottom-sheet legend and 2–4 simple filter chips.
- Keep overlays minimal to preserve performance (UX-D-041) and outdoor legibility (UX-D-046).

---

## Trust & Stability posture (low-trust environments) (UX-D-042 / UX-D-043)
**Intent:** Convey robustness and certainty in markets where fraud and system unreliability are salient fears.

### Delivery identity (v1 fallback)
- The UI may present a driver “ID badge” style card (UX-D-035), but **backend support determines availability**:
  - If the API provides driver identity/vehicle assignment fields for an order, show the **ID badge** prominently.
  - If not provided (v1 baseline), fall back to showing **seller identity** (seller principal / seller listing identity) as the accountable party.
- This prevents frontend teams from assuming a driver-dispatch concept exists in the API unless explicitly added to the contract.

### Visual weight (industrial stability)
- Avoid “ephemeral” visual language:
  - no hairline strokes for primary dividers/controls
  - avoid ultra-light typography for key labels and primary CTAs
- Prefer “engineered” structure:
  - clear containers/cards with visible edges
  - substantial buttons with obvious affordances (they should feel pressable)
  - hierarchy that reads at a glance (big primary, clear secondary)
- Keep whitespace intentional:
  - enough spacing for readability and touch targets
  - not so airy that the screen looks empty or fragile

### Tangible feedback loops (what gets haptics/sound)
- **Always provide immediate confirmation** on state-changing actions:
  - visual state change (button state, inline status, confirmation surface)
  - haptic cue for primary actions
- **Mechanical sound effects** are allowed as reinforcement for high-stakes actions (e.g., “confirm order”), but must follow these rules:
  - Respect OS mute/silent and accessibility settings; never force sound.
  - Never make sound the only confirmation (visual + haptic must still confirm).
  - Keep sounds subtle and infrequent (no “noisy UI”).

### Recommended feedback mapping (v1)
- **Primary CTA press** (e.g., Order/Confirm/Accept): light “click” haptic + immediate pressed state.
- **Successful commit** (order created / accepted): stronger “thud” haptic + clear success state.
- **Failure** (rejected/offline/timeout): distinct haptic pattern + diagnostic card (UX-D-039), no cryptic codes.

---

## Iconography rules — Semi-abstract + hybrid states (UX-D-044 / UX-D-045)
**Intent:** Reduce translation burden and increase recognition for low-literacy users using icons that look like “things,” not UI metaphors.

### The semi-abstract spectrum (what we choose)
- **Avoid photorealism**:
  - no photos as icons (currency photos, documents, specific vehicle photos) — too market-specific and visually noisy.
- **Avoid pure abstraction**:
  - do not rely on “computer literacy” metaphors as the primary meaning (e.g., gear = settings) unless paired with a clear label and used consistently.
- **Default: semi-abstract line art**:
  - simplified line drawings that preserve the core silhouette (e.g., generic banknote, generic person, generic water droplet, generic truck outline).
  - align with “Blueprints of Life” technical language.

### Hybrid state rule (navigation + selection)
- **Active/selected**: **solid (filled)** icon variant.
- **Inactive**: **outline** variant.
- Requirements:
  - Same glyph/silhouette between variants (only fill changes).
  - Active state must also have a redundant cue (label weight/color) so color alone is not the only signal.

### Clarity and accessibility checklist (v1)
- Icons must be recognizable:
  - at minimum tab/icon sizes
  - in bright sunlight / low contrast conditions
- Don’t communicate meaning by icon alone for safety- or money-critical actions:
  - pair with a short label (controlled vocabulary) where stakes are high.
- Keep stroke weights substantial enough to avoid “hairline disappearance” on older Android screens.

---

## Navigation & screen structure — Ruthless simplicity (UX-D-047)
**Intent:** Make the app usable for novice smartphone owners by reducing two-dimensional scanning, deep menus, and multi-choice overload.

### One primary task per screen (default)
- Each screen must have **one clear primary action** (biggest, most prominent).
- Secondary actions exist, but are visually de-emphasized (smaller, lower contrast, secondary placement).
- Avoid screens that ask the user to compare many options at once; prefer progressive disclosure.

### Single-column layouts (default)
- Prefer a single vertical content column for primary flows.
- Avoid multi-column grids and complex “dashboard mosaics” that require scanning in two dimensions.

### Step-by-step (“wizard”) flows for complex tasks
- For complex or unfamiliar tasks (setup, ordering, calibration), prefer a **linear sequence**:
  - one question/task at a time
  - clear “Next” progression
  - visible progress indicator when helpful (e.g., “Step 2 of 4”)
- Avoid hub-and-spoke “menu of submenus” for novice-first tasks.

### Large cards/buttons over dense menus
- Use large cards or buttons for key choices; avoid dense lists of small tap targets or nested menus.

---

## Consistency & predictability doctrine (UX-D-048)
**Intent:** Help users build a mental model quickly by reusing the same patterns, placements, and meanings everywhere.

### Immediate feedback on every tap
- Every interactive element must show a pressed/active state immediately.
- For state changes, show a clear result state:
  - checkmark, inline status, confirmation surface, or progress state (depending on context)
- For “money/order” actions, also follow Tangible Feedback rules (UX-D-043).

### Consistent meaning + consistent placement
- The same concept uses the same label and icon everywhere (no drift).
- Keep navigation placement consistent:
  - persistent bottom navigation where applicable
  - consistent placement for back/help/alerts across screens

### Pattern minimization (anti-drift)
- Prefer a small set of patterns reused everywhere over bespoke per-screen UI.
- If a new interaction pattern is introduced, it must be justified and documented as a DECIDED pattern.

---

## First-run onboarding & engagement (MA-006 / MA-008)
**Intent:** Hook users early without overwhelming them; teach the core loop visually and keep first value fast.

### First-run tutorial (2–3 screens, skippable)
- Keep to **2–3 panels max**. Each panel communicates one idea:
  - “Know your water” (monitoring)
  - “Avoid running out” (risk + last updated)
  - “Order refill” (replenishment)
- Use canonical visuals:
  - Blueprint-style line art / semi-abstract iconography (vector-first) to minimize data and translations.
- Minimal copy:
  - one short headline + one short line (localized); no paragraphs.
- Always include **Skip** and land on a usable entry path (per MA-001/MA-030).

### Adaptive prompting (registration timing)
- Do not block read-only exploration behind account creation where v1 allows it (community discovery).
- For authenticated flows, keep registration prompts short and explain the benefit (sync, alerts, ordering).

### Progressive disclosure
- Do not expose advanced features on first run.
- Use step-by-step (“wizard”) flows for complex tasks (UX-D-047).

### Education by showing (micro-help)
- Prefer coach marks/tooltips that are:
  - illustration-led (Blueprints of Life line art)
  - one action at a time
  - dismissible and not spammy (show once unless user asks again)
- For non-standard interactions (pull-to-refresh/mechanical refresh), use a simple visual hint first time.

### Empty states (no blank screens)
- Empty states must explain “what to do next” with:
  - a simple illustration
  - one primary CTA
  - minimal text
