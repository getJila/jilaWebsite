# Jila Mobile App — Language, Accessibility & UI Basics (Core)

> **Status:** Condensed / low-drift reference
> 
> **Last updated:** 2025-12-20

## Purpose
Keep UX fundamentals consistent (language, accessibility, and a few UI invariants) without turning this folder into a full design/copy system.

## Localization
- **Primary language**: Portuguese (pt-AO)
- **Secondary**: English
- **Rules**
  - All user-facing strings are externalized (no hardcoded copy).
  - Date/time/number formatting uses locale-aware formatting.
  - Portuguese strings may be longer; UI must allow reasonable expansion.

## Copy & vocabulary (controlled terms)
Keep terms consistent across UI, notifications, and support.

- **Reservoir**: “Reservatório”
- **Water level**: “Nível da água”
- **Days remaining**: “Dias restantes”
- **Order**: choose one term (recommended: “Encomenda”) and **do not mix** with synonyms.
- **Seller**: “Vendedor”
- **Supply point**: “Ponto de abastecimento”

## Accessibility (v1 baseline)
- **Target**:
  - **Body text**: WCAG 2.1 **AAA (≥ 7:1)** contrast ratio. This is required for outdoor readability in direct sunlight (UX-P-001 / UX-D-046).
  - **Other UI**: WCAG 2.1 **AA minimum**; prefer AAA where feasible, especially for critical alerts and primary CTAs.
- **Touch targets**: minimum ~48×48dp for interactive elements.
- **Color is never the only signal**: pair with icons/text (UX-P-005).
- **Screen reader support**: meaningful labels for interactive elements; correct reading order on key screens.
- **Dynamic text**: support system font scaling; prevent truncation of critical info.

### Outdoor readability (“Solar Mode”) (v1)
- **Requirement**: Provide a **High Contrast Light Mode** for intense sunlight conditions (UX-P-001 / UX-D-046).
- **Behavior (v1)**:
  - May switch automatically using the ambient light sensor where available, but must avoid flicker (use hysteresis / stable thresholds).
  - Must allow a user override (manual toggle) and respect OS accessibility preferences.
- **Canonical details**: `docs/design/jila_design_decision_register.md` + `docs/ux/jila_design_guide.md` (Contrast & Solar Mode)

## UI invariants (v1)
- **Forms**: labels above inputs; inline validation; preserve user input on error.
- **State clarity**: saved/saving/pending sync/failed is always visible where it matters.
- **Critical indicators**: low/critical water and order status must be understandable at a glance.

## Non-goals
- Token catalogs, full translation tables, or platform-specific implementation code.

## References
- UX guidelines: `../../ux/jila_application_ux_guidelines.md`
