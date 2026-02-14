# Decision Registers — Canonical Index (Anti-drift)

This folder is the canonical entry point for **decision registers**, split by platform.

Rule: once a decision is **DECIDED**, other docs must **reference** the decision register entry and must not restate
alternative options or "Option C".

---

## Platforms

## Cross-platform (shared)

### Canonical design principles
- `docs/design/jila_canonical_design_principles.md` (UX-P-001..016)

### Theme and brand tokens
- `docs/design/jila_theme_and_brand_tokens_v1.md`

### Design decisions (design system)
- `docs/design/jila_design_decision_register.md`

### API (backend)
- Canonical decision register: `docs/architecture/jila_api_backend_decision_register.md`
- Scope: HTTP/API semantics, auth/session policy, DB/infra/ops decisions, outbox/events, telemetry semantics.

### Portal (web)
- Canonical decision register: `docs/decision_registers/web_portal_decision_register.md`
- Canonical UI specs (implementation-oriented, not a decision register):
  - `docs/design/01_design_tokens_spec.md`
  - `docs/design/02_component_patterns_spec.md`

### App (mobile)
- Product decisions (flows, scope, sequencing): `docs/decision_registers/mobile_app_decision_register.md`
- Narrative / implementable guidance (derived from DECIDED items): `docs/ux/jila_design_guide.md`

