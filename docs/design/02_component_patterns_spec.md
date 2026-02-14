---
title: Jila UI — Component Patterns Specification (v1) (MUI-first)
status: DECIDED
last_updated: 2026-01-14
related_decisions:
  - UX-D-049 (Graceful missing states)
  - WP-090 (Design token consolidation)
sources:
  - ./jila_theme_and_brand_tokens_v1.md
  - ./01_design_tokens_spec.md
---

## Purpose

Define the **canonical UI component patterns** for Jila’s web surfaces, expressed as **theme + behavior guidance** intended
to be implemented as a **shared MUI (Material UI) theme configuration**.

This document specifies:
- what variants exist and when to use them
- what behaviors are required (states, feedback, accessibility)
- how patterns map onto MUI components and theming

## Canonical sources (do not drift)

- Cross-platform theme + brand semantics: `./jila_theme_and_brand_tokens_v1.md`
- Web theme mapping/derivations (hover alphas, focus rings, glass effects): `./01_design_tokens_spec.md`
- Canonical design principles: `./jila_canonical_design_principles.md`

## Global UX inheritance (do not drift)

These apply to all components/patterns described here:
- Outdoor-first contrast posture (UX-P-001)
- Color is never the only signal (UX-P-005)
- Limited semantic palette / stable meaning (UX-P-008)
- Industrial clarity over fragile aesthetics (UX-P-009)

---

## 1) Buttons (MUI: `Button`, `IconButton`)

### 1.1 Variants (canonical)

- **Primary**: the main CTA on a surface.
  - MUI mapping: `Button variant="contained" color="primary"`
- **Secondary**: supporting action (cancel/back/alternate).
  - MUI mapping: `Button variant="outlined" color="inherit"` (or `color="secondary"` depending on surface)
- **Tertiary / Link**: low-emphasis action.
  - MUI mapping: `Button variant="text" color="primary"`
- **Destructive**: deletes/disconnects/revokes; must be clearly labeled.
  - MUI mapping: `Button variant="contained" color="error"`

### 1.2 States (required)

- **Hover/focus/pressed**: must be visible and consistent.
- **Disabled**: must convey "not available" without looking broken.
- **Loading**: for async actions, show immediate feedback (disabled state + progress indicator) to prevent double-submit.
  - Behavioral guidance: per UX-D-049, use inline progress indicators; avoid `@mui/lab` components due to breaking change risk.

### 1.3 Content rules

- **Primary actions must be labeled** (no icon-only primary CTAs).
- Icon-only actions use `IconButton` and must have an accessible label (`aria-label` / tooltip).

---

## 2) Form controls (MUI: `TextField`, `Select`, `Checkbox`, `Radio`, `Switch`)

### 2.1 Default field style

- Use **outlined** fields by default (industrial clarity, legible boundaries).
  - MUI mapping: `TextField variant="outlined"`, `FormControl variant="outlined"`
- Labels must be visible and consistent (avoid placeholder-only labeling).
- Helper text and error text appear directly below the field.

### 2.2 Validation and error display (required)

- Validation timing: **blur + submit** (avoid noisy per-keystroke errors).
- Prefer **field-level** errors; form-level errors only when necessary.
- Error states must use **redundant encoding**:
  - color + icon + short message (UX-P-005).
  - MUI mapping: `TextField error helperText`, plus optional `InputAdornment` icon.

### 2.3 Input adornments and affordances

- Use start/end adornments for icons (email, password show/hide, search).
  - MUI mapping: `InputAdornment`, `IconButton` in `endAdornment` for password visibility.
- Toggle controls (checkbox/switch) must remain readable on light backgrounds and in glare.

---

## 3) Status, badges, and chips (MUI: `Chip`, `Badge`, `Alert`)

### 3.1 Status representation (required)

Status must never be color-only. Use:
- **Chip** (label + optional icon) for small status signals.
- **Alert** for in-context warnings/errors that require attention.

### 3.2 Canonical semantic meanings

Use semantic colors per `./jila_theme_and_brand_tokens_v1.md`:
- `success`, `warning`, `info`, `error`, `critical` (domain risk)  

Notes:
- Do not invent new semantic colors for roles (e.g., avoid purple-as-semantics). If roles need badges, use a **neutral**
  style (outline/grey) unless there is a safety or state meaning.

---

## 4) Cards & panels (MUI: `Paper`, `Card`)

### 4.1 Surfaces

- Prefer clear container boundaries (UX-P-009).
- “Glass” is an **effect**, not a brand token. If used:
  - keep it subtle, flat (no meaning-bearing gradients)
  - ensure text contrast remains AAA where required
  - define it via theme overrides using computed values from `01_design_tokens_spec.md` (blur/alpha)

### 4.2 KPI/stat cards

- KPI numbers should be high-contrast and scannable.
- If showing delta/change, encode with color + icon + label (e.g., “↑ +12%”).

---

## 5) Tables and list surfaces (MUI: `Table`, optional `DataGrid`)

### 5.1 Table structure

- Provide a stable header row, predictable column alignment, and clear row hover/focus states.
- Use an explicit “density” posture (comfortable vs compact) rather than accidental drift.

### 5.2 Toolbars and filters

Canonical layout (when present):
- left: search
- middle: segmented status filters (tabs/chips)
- right: advanced filters + primary action

MUI mapping:
- Search: `TextField` with start adornment icon
- Filters: `Tabs` or `Chip` group
- Primary action: `Button` (Primary)

### 5.3 Empty/loading/error states (required)

- Loading: `Skeleton` (not a full-page spinner).
- Empty: one illustration/icon + one headline + one primary action.
- Error: inline `Alert` with one recovery action (retry/refresh).

---

## 6) Modals & confirmations (MUI: `Dialog`)

### 6.1 Confirmation patterns

- Use in-app dialogs for confirmations (avoid browser-native confirm/alert).
- Destructive confirmations must:
  - clearly describe consequence
  - provide a safe default (cancel)
  - use redundant encoding (icon + label, not color-only)

MUI mapping:
- `Dialog` with `DialogTitle`, `DialogContent`, `DialogActions`
- Destructive action uses `Button color="error"`

---

## 7) Navigation (MUI: `AppBar`, `Drawer`, `Tabs`, `Breadcrumbs`)

### 7.1 Navigation anchors (required)

- Titles and primary actions must appear in consistent locations across screens.
- Navigation state must be legible without relying on color alone (active indicator + label weight).

---

## 8) Feedback states (MUI: `Snackbar`, `Alert`, `Skeleton`)

### 8.1 Toasts/snackbars

- Use snackbars for transient feedback (saved, failed), but do not hide recoverable errors in toast-only UX.
- Prefer an in-context `Alert` when user action is required.

### 8.2 Freshness indicators

- When showing “last updated” or freshness warnings, keep copy short and avoid false precision.
- If data is stale, show an explicit freshness signal (label + timestamp) and a recovery action when applicable.

---

## 9) Accessibility & contrast (non-negotiable)

- Body text contrast posture is **AAA (≥ 7:1)** (UX-D-046).
- Interactive targets must meet minimum touch/click targets.
- Keyboard navigation: visible focus ring on all interactive elements.
- All icon-only controls must have accessible labels.

---

## 10) Implementation checklist (MUI package)

- [ ] Use a shared `createTheme()` configuration wired to `./jila_theme_and_brand_tokens_v1.md` base tokens.
- [ ] Provide explicit component variants (Primary/Secondary/Tertiary/Destructive) via theme configuration (not custom wrapper components per WP-012).
- [ ] Standardize empty/loading/error components (`EmptyState`, `LoadingSkeleton`, `InlineError`).
  - Note: If these are implemented as reusable components (vs inline patterns), they require WP-012 approval in the decision register.
- [ ] Ban browser-native confirm/alert in product UX; use the shared dialog pattern.
- [ ] Ensure contrast and focus states meet requirements on both light and dark surfaces.

