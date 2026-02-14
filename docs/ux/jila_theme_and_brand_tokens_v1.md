# Jila — Theme & Brand Tokens (v1) (Canonical, Cross-Platform)

This document is the **single source of truth** for Jila theme and brand tokens across **all** product surfaces
(mobile app, web portal, any future clients).

Rule: platform-specific docs (React Native, web, etc.) must **reference** this document and must not redefine
base token meanings/values. Platform docs may define **derived** tokens (hover/alpha/rings) and must label any
intentional deviations as a **platform exception** with rationale.

Canonical principles:
- `docs/ux/jila_canonical_design_principles.md` (UX-P-001..)
- `docs/ux/jila_design_decision_register.md` (DECIDED items, components/patterns)

---

## 1) Color tokens (brand + semantic) (v1)

Intent: provide a minimal, stable set of base colors that encode consistent meaning across platforms.

### 1.1 Semantic meaning contract (v1) — do not drift

- `success`: successful completion / “safe to proceed”.
- `warning`: attention / “in motion” / degraded-but-not-failed. **Culturally safer** alternative to red for non-failure
  emphasis (see UX-P-003).
- `error`: failure states (validation errors, API/request failures, action could not complete).
- `critical`: domain severity / risk state (e.g., water risk = CRITICAL). This may appear even when nothing “failed”.
- `info`: non-status informational highlight (links, safe highlights). Do **not** use as a risk/severity state.
- `primary` / `secondary`: brand + navigation accents (not status semantics).

Non-negotiables:
- Body text must meet WCAG 2.1 **AAA (≥ 7:1)** (UX-D-046).
- Color is never the only signal (UX-P-005): pair **color + icon + label** for semantic states.
- Reserve “true red” for failures/alerts only (UX-P-003).

### 1.2 Base palette (v1)

**Brand**
- `primary` (Aqua Teal / water accent): `#4ECDC4`
- `secondary` (Deep Ocean Blue): `#1950B8`

**Surfaces**
- Dark/default:
  - `background`: `#0D1B2A` (Midnight Navy)
  - `surface`: `#111C2C`
  - `surface_variant`: `#18253A`
- Solar Mode / High Contrast Light:
  - `background_solar`: `#FFFFFF`
  - `surface_solar`: `#EAF3FF` (pale sky surface; keep text dark)
- OLED energy surface:
  - `background_oled`: `#000000`

**Text**
- Dark surfaces:
  - `text_primary_dark`: `#FFFFFF`
  - `text_secondary_dark`: `#D1D5DB`
- Light surfaces:
  - `text_primary_light`: `#000000`
  - `text_secondary_light`: `#1F2937`

**Semantic**
- `success`: `#22C55E`
- `warning` (warm orange / terracotta): `#D87C4A`
- `critical`: `#DC2626`
- `error`: `#EF4444`
- `info`: `#248CFF`

**Borders/dividers**
- `outline_dark`: `#223046`
- `outline_light`: `#D1D5DB`

### 1.3 Derived tokens (allowed, platform-owned)

Platforms may define derived tokens such as:
- hover variants (e.g., `primary_hover`)
- alpha tints (e.g., `primary/10`)
- focus rings (e.g., `primary_glow`)

Constraint: derived tokens must be **computed from** the base palette above; do not introduce a new “primary” color.

---

## 2) Typography (v1)

Intent: consistent “Data vs. Narrative” voice across products (UX-D-011).

### 2.1 Font families and roles (canonical)
- **IBM Plex Sans (Narrative/UI voice)**: body copy, labels, UI text, descriptions, guidance.
- **Silka Mono (Data voice)**: numeric readings (water level %, liters/volume, price/currency, dates/timestamps, IDs, logs, tables).

### 2.2 Allowed weights (canonical)
Do not use the full families; keep the system quiet and consistent.

- **IBM Plex Sans**: `400`, `500`, `600`
- **Silka Mono**: `400`, `500`

Disallowed (unless a DECIDED exception is added):
- IBM Plex Sans `300` (too weak on screens)
- `700+` weights (visual shouting)
- Casual italics (use sparingly or not at all)

### 2.3 Global rules (canonical)
- Do not use Silka Mono for paragraphs; it is for numbers/data only.
- Do not switch fonts between product surfaces and website; brand unity is non-negotiable.
- Use opacity/size/spacing for hierarchy before jumping to heavier weights.
- Typography must support Portuguese diacritics at minimum.
- **Strict no-fallback**: do not use fallback font stacks; load the canonical fonts before render.

### 2.4 Numeric behavior (canonical)
- Use **tabular numbers** for aligned numeric columns, KPIs, dashboards, and data tables.
- Format numbers locale-aware; always show thousand separators.
- Separate units with a **thin space** (`12.4 L`, `3 m³`, `85 %`) unless a standardized locale format is adopted.
- Emphasize values with weight, not color; avoid bolding units.
- For web/CSS, enable `font-variant-numeric: tabular-nums` on data surfaces.

### 2.5 Line-height rules (canonical)
**IBM Plex Sans**
- Body (14–16 px): `1.45–1.5`
- Long-form reading (16–18 px): `1.55–1.6`
- Labels / UI controls (12–14 px): `1.3–1.4`
- Headings (any size): `1.15–1.25` (never exceed `1.25`)

**Silka Mono**
- Tables / inline values (12–14 px): `1.35–1.4`
- KPIs (16–24 px): `1.2–1.3`
- Logs (12 px): `1.4`

### 2.6 Letter-spacing rules (canonical)
**IBM Plex Sans**
- Body: `0`
- Labels / buttons: `+0.01em`
- All-caps labels: `+0.04–0.06em`
- Headings: `-0.01em` (optional; use only if large sizes feel tight)

**Silka Mono**
- Default: `0`
- Dense tables: `+0.02em`
- Very small mono (≤12 px): `+0.03em`
- Never tighten mono (no negative tracking).

### 2.7 Typography variants (v1)

These functional variants use the Data Voice (mono font) for displaying numeric/data information consistently across platforms.

| Variant | Font | Size | Weight | Use case |
|---------|------|------|--------|----------|
| `kpi` | Mono | 32px / 2rem | 500 | Primary KPI/metric displays (e.g., "78%" water level) |
| `reading` | Mono | 24px / 1.5rem | 400 | Sensor readings, secondary metrics (e.g., "1,250 L") |

Rules:
- Both variants use the Data Voice font (Silka Mono canonical)
- Sizes are reference values; platforms may scale proportionally for screen density
- Use `kpi` for hero metrics, `reading` for supporting data

---

## 3) Spacing + radius scale (v1)

Intent: keep layouts “engineered” and consistent (UX-D-012).

### 3.1 Spacing scale (dp/px)
- `xs=4`, `sm=8`, `md=12`, `lg=16`, `xl=24`, `2xl=32`, `3xl=48`

### 3.2 Radius scale (dp/px)
- `sm=8`, `md=12`, `lg=16`
- Defaults: cards `md`, buttons `md`, dialogs/bottom-sheets `lg`

Web mapping note:
- Web implementations may express these as `px` or `rem` equivalents, but must preserve the **same numeric steps**
  (4/8/12/16/24/32/48 and 8/12/16).

---

## 4) Platform mappings (non-canonical implementation details)

### 4.1 React Native (Paper / MD3) mapping (v1)

Intent: map canonical tokens into Paper MD3 theme slots without changing meaning.

- Map `primary/secondary/background/surface/error/outline` to MD3 equivalents.
- **onPrimary guidance (v1)**:
  - Because `primary` is a light teal in v1, `onPrimary` must be a **dark** text color to meet AAA outdoors (typically
    `text_primary_light`/black, or a dark navy aligned to the surface system).

### 4.2 Web portal theme mapping (v1)

Intent: map canonical tokens into a web UI theme configuration without redefining base colors.

- Web token docs must reference this file for:
  - `primary`, `secondary`, surfaces, text, semantic colors
- Web token docs may define:
  - hover/focus/ring alphas
  - “glass” effect alphas/blur values (these are effects, not brand base colors)

