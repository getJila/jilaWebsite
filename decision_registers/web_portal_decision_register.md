# Jila — Web Portal Decision Register (Anti-ambiguity) (v0.1)

Purpose: track **web portal technical choices** (UI library, styling, state management, utilities) so implementation doesn't drift across features/screens.

Principle: once a decision is **DECIDED**, other docs/tickets must reference it and must not re-introduce alternates.

---

## 0) Canonical map (do not drift)
- Design tokens (v1): `docs/design/01_design_tokens_spec.md`
- Component patterns: `docs/design/02_component_patterns_spec.md`
- **Layout spec**: `docs/design/03_web_layout_spec.md`
- Web Portal PRD: `docs/pm/web_portal/01_web_portal_prd.md`
- **Folder structure**: `docs/architecture/web_portal/01_folder_structure.md`
- **Shared components**: `docs/architecture/web_portal/02_shared_components.md`
- Design decision register (UX): `docs/design/jila_design_decision_register.md`
- Mobile decision register: `docs/decision_registers/mobile_app_decision_register.md`
- Canonical design principles: `docs/design/jila_canonical_design_principles.md`
- Theme and brand tokens: `docs/design/jila_theme_and_brand_tokens_v1.md`

---

## 1) Ownership and change policy

### WP-001 — Ownership model for web portal decisions
- **Status**: DECIDED (2026-01-14)
- **Decision (v1)**:
  - **Accountable owner (final decider)**: **PM**.
  - **Expected reviewers**: design + engineering leads review for coherence, feasibility, and drift prevention (PM remains final).
  - **Change bar for DECIDED items**: requires a short rationale and must update this register in the same change.
- **Why it matters**: without a clear owner/process, technical choices and component patterns will drift quickly.

---

## 2) UI Library & Styling

### WP-010 — MUI 7 as canonical UI library
- **Status**: DECIDED (2026-01-14)
- **Decision (v1)**: MUI 7 (`@mui/material` + `@mui/x-*`) is the **exclusive** UI component library.
  - Includes MUI X for DataGrid, DatePickers, and advanced components.
- **Why it matters**: consistent design system, comprehensive component coverage, active maintenance.

### WP-011 — No Tailwind CSS
- **Status**: DECIDED (2026-01-14)
- **Decision (v1)**: Tailwind CSS is **forbidden**. All styling via MUI's `sx` prop and `styled()` API.
- **Why it matters**: single styling paradigm, better theme integration, reduced bundle size.

### WP-012 — MUI-only component policy (CRITICAL GUARDRAIL)
- **Status**: DECIDED (2026-01-14)
- **Decision (v1)**: Custom components that duplicate or extend MUI functionality require **explicit approval** in this decision register BEFORE implementation.
- **Process (v1)**:
  1. Check if MUI X has the component.
  2. Compose from MUI primitives.
  3. If truly missing, create a WP-XXX entry with justification.
- **Approved custom components**: (None yet — see Section 9)
- **Why it matters**: prevents component sprawl, ensures consistency, leverages MUI's accessibility.

### WP-013 — Thin wrappers pattern
- **Status**: DECIDED (2026-01-14)
- **Decision (v1)**: MUI components wrapped in thin project-specific wrappers in `shared/ui/` for consistency.
  - Example: `<JilaButton>` wraps `<Button>` with project defaults.
- **Criteria for allowed wrappers (v1)**:
  1. Wrapper sets **prop defaults only** (e.g., default variant, default size).
  2. Wrapper adds **no new behavior** or visual variants beyond MUI's API.
  3. Wrapper is **explicitly listed** in Section 9 (Approved Custom Components).
- **Process**: If a wrapper needs new behavior, it must go through the WP-012 approval process.
- **Why it matters**: centralized defaults, easier theme updates, consistent API, prevents wrapper sprawl.

### WP-014 — Custom MUI theme from design tokens
- **Status**: DECIDED (2026-01-14)
- **Decision (v1)**: Create custom MUI theme mapping Jila design tokens (colors, typography, spacing).
  - **Canonical tokens (v1)**: `docs/design/jila_theme_and_brand_tokens_v1.md`
- **Light theme (Solar Mode) (v1)**: Web light theme = Solar Mode (outdoor high-contrast).
  - **Surfaces**: Flat colors only — `#FFFFFF` (canvas), `#EAF3FF` (panels). No gradients on UI surfaces.
  - **Text contrast**: AAA body text contrast (≥ 7:1).
  - **Primary button text**: `palette.primary.contrastText` = `#000000` (black text on teal CTAs for glare readability).
  - **No separate "office light" theme** in v1 — Solar Mode serves both indoor and outdoor use.
- **Dark theme (v1)**: OLED-friendly true-black surfaces per UX-P-004.
- **Why it matters**: brand consistency across platforms; outdoor readability is a first-class requirement.

### WP-015 — 'critical' semantic color (domain risk state)
- **Status**: DECIDED (2026-01-14)
- **Decision (v1)**: Add `palette.critical` to MUI theme for domain risk states distinct from `error`.
  - **Value**: `{ main: '#DC2626', contrastText: '#FFFFFF' }`
  - **Usage**: `critical` = risk/severity state (tank low, threshold breach) — may appear when nothing has failed.
  - **Contrast**: `error` = failure state (API error, validation failure, system problem).
- **Constraints (v1)**:
  - Redundant encoding required: `critical` must always be paired with icon + label (UX-P-005).
  - Never use `critical` color alone to communicate risk.
- **Why it matters**: Distinguishes "your water is low" (risk) from "something broke" (error), reducing user confusion.

### WP-016 — Portal layout specifications
- **Status**: DECIDED (2026-01-14)
- **Decision (v1)**:
  - **Topbar height**: 64px (fixed)
  - **Sidebar widths**: 240px (expanded), 64px (collapsed, icon-only)
  - **Content max-width**: 1280px (centered when viewport exceeds)
  - **Breakpoints**: MUI defaults (xs=0, sm=600, md=900, lg=1200, xl=1536)
  - **Sidebar behavior**:
    - Hidden below md (900px) — hamburger menu instead
    - Collapsed (64px) at md–lg (900–1199px)
    - Expanded (240px) at lg+ (≥1200px)
  - **Content padding**: 16px (xs–sm), 24px (md), 32px (lg+)
- **Spec document**: `docs/design/03_web_layout_spec.md`
- **Why it matters**: Consistent layout dimensions prevent drift and enable shared component reuse across all portal screens.

### WP-017 — Shared component catalog
- **Status**: DECIDED (2026-01-14)
- **Decision (v1)**: All shared components must be documented in `docs/architecture/web_portal/02_shared_components.md` before implementation.
  - Components used by 2+ features **must** be in `shared/ui/` or `shared/form/`
  - Feature-specific components stay in `features/<feature>/components/`
  - Naming conventions defined in the catalog must be followed
- **Component categories (v1)**:
  - `shared/ui/badges/` — Status, severity, role badges
  - `shared/ui/data-display/` — Timestamps, percentages, KPIs
  - `shared/ui/identity/` — Avatars, user info
  - `shared/ui/layout/` — Shell, sidebar, headers, toolbars
  - `shared/ui/state/` — Empty, loading, error states
  - `shared/ui/lists/` — Pagination, cards, tables
  - `shared/form/` — Form field wrappers
- **Catalog document**: `docs/architecture/web_portal/02_shared_components.md`
- **Why it matters**: Prevents duplicate components with similar names, ensures consistent patterns, reduces technical debt.

### WP-090 — Design token consolidation (single source of truth)
- **Status**: DECIDED (2026-01-14)
- **Decision (v1)**: `docs/design/jila_theme_and_brand_tokens_v1.md` is the **single source of truth** for base brand colors and semantic meanings.
  - Web (and other platforms) may only define **derived** tokens (hover alphas, focus rings, glass effects) computed from the canonical base.
  - Web docs **must not** redefine base colors or change semantic meanings.
- **v1.1 update (2026-01-14)**: See UX-D-050 for canonical token additions:
  - Typography variants (`kpi`, `reading`) for data display
  - Spacing naming standardized (`base=16`, not `lg=16`)
  - Explicit `onPrimary: #000000` for contrast
  - Glass effect parameters standardized cross-platform
- **Enforcement (v1)**:
  - `docs/design/01_design_tokens_spec.md` defines web-specific computed values only.
  - Any new semantic color requires cross-platform decision in the design decision register first.
- **Why it matters**: Prevents "multiple primaries" and conflicting semantics across mobile + web.

---

## 3) Icons

### WP-020 — Icon libraries
- **Status**: DECIDED (2026-01-14)
- **Decision (v1)**: Material Community Icons (MCI) is the **authoritative source** for cross-platform icon names (per UX-D-030). MUI Icons (`@mui/icons-material`) may be used for web-specific icons not available in MCI.
- **Cross-platform rule**: When an icon is needed on both mobile and web, use the MCI icon name as the canonical reference.
- **Why it matters**: ecosystem consistency + mobile alignment.

---

## 4) Data & State

### WP-030 — TanStack Query for data fetching
- **Status**: DECIDED (2026-01-14)
- **Decision (v1)**: TanStack Query (React Query) for server state (aligned with mobile MA-023).
- **Why it matters**: caching, background updates, consistent with mobile.

### WP-031 — Zustand for global state
- **Status**: DECIDED (2026-01-14)
- **Decision (v1)**: Zustand for client-side global state management.
- **Why it matters**: minimal boilerplate, TypeScript-friendly, small bundle.

### WP-032 — NextAuth.js for authentication
- **Status**: DECIDED (2026-01-14)
- **Decision (v1)**: NextAuth.js (Auth.js) for session management.
- **Why it matters**: Next.js native, secure defaults, provider flexibility.

### WP-033 — Native fetch with TanStack Query
- **Status**: DECIDED (2026-01-14)
- **Decision (v1)**: Use native `fetch` API (no axios). TanStack Query handles caching/retry.
- **Why it matters**: smaller bundle, modern API, sufficient for needs.

---

## 4.1) Client Persistence & Offline

### WP-034 — localStorage for client persistence
- **Status**: DECIDED (2026-01-14)
- **Decision (v1)**: Use browser `localStorage` for simple client-side persistence. TanStack Query cache handles server state persistence.
- **Constraints (v1)**:
  - Never store secrets/tokens in localStorage (use httpOnly cookies via NextAuth)
  - Use for: UI preferences, dismissed hints, last-used filters
- **Why it matters**: simple API, no external dependencies, sufficient for web use cases.

### WP-035 — TanStack Query offline mode
- **Status**: DECIDED (2026-01-14)
- **Decision (v1)**: Rely on TanStack Query's built-in offline support for web. No explicit offline queue implementation (unlike mobile MA-025).
- **Behavior (v1)**:
  - Stale data shown when offline
  - Mutations retry on reconnect
  - No optimistic offline writes for critical actions (orders, auth)
- **Why it matters**: simpler implementation, web users typically have better connectivity than mobile.

### WP-036 — Web push notifications (planned)
- **Status**: DECIDED (2026-01-14)
- **Decision (v1)**: Web push notifications are **planned** using Firebase Cloud Messaging (FCM) via service workers.
- **Scope (v1)**:
  - Aligned with mobile notification categories: `orders`, `water_risk`, `device_risk`
  - Same preference groups as mobile (MA-027)
  - Implementation deferred to post-v1 but architecture should not block it
- **Why it matters**: cross-platform notification parity for multi-site organization users who use web portal.

---

## 5) Forms

### WP-040 — React Hook Form + Zod
- **Status**: DECIDED (2026-01-14)
- **Decision (v1)**: React Hook Form with Zod validation (aligned with mobile MA-024).
- **Why it matters**: performance, TypeScript integration, mobile consistency.

---

## 6) Visualization & Maps

### WP-050 — Mapbox GL JS for maps
- **Status**: DECIDED (2026-01-14)
- **Decision (v1)**: Mapbox GL JS (aligned with mobile MA-028).
- **Why it matters**: cross-platform consistency, feature parity.

### WP-051 — Recharts for data visualization
- **Status**: DECIDED (2026-01-14)
- **Decision (v1)**: Recharts for charts (not MUI X Charts).
- **Why it matters**: mature, flexible, composable API.

---

## 7) Utilities

### WP-060 — date-fns for date/time
- **Status**: DECIDED (2026-01-14)
- **Decision (v1)**: date-fns for date/time manipulation.
- **Why it matters**: tree-shakable, immutable, comprehensive.

### WP-061 — No animation library
- **Status**: DECIDED (2026-01-14)
- **Decision (v1)**: No animation library (Framer Motion, React Spring). Use CSS transitions and MUI's built-in transitions only.
- **Why it matters**: performance, simplicity, reduced bundle.

---

## 8) Testing

### WP-070 — Playwright E2E only
- **Status**: DECIDED (2026-01-14)
- **Decision (v1)**: Playwright for E2E testing. No unit test library (Vitest/Jest).
- **Why it matters**: E2E covers critical paths, reduced test maintenance overhead.

---

## 9) Approved Custom Components

This section tracks custom components approved via the WP-012 process. Each entry must include:
- Component name and purpose
- Justification (why MUI/MUI X doesn't suffice)
- Approval date

**Approved components**: (None yet)

---

## 10) Decisions log (template)

Use this template for new entries:
- **Status**: OPEN | DECIDED
- **Decision needed / Decision**
- **Why it matters**
