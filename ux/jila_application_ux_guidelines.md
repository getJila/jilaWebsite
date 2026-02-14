## Jila UX guidelines (index)

### Purpose
Keep **Jila-wide UX guardrails** discoverable while avoiding duplicate, drifting copies across docs.

### Canonical (cross-platform)
- Canonical design principles: `docs/design/jila_canonical_design_principles.md` (UX-P-001..016)
- Theme and brand tokens: `docs/design/jila_theme_and_brand_tokens_v1.md`
- Design decisions (design system): `docs/design/jila_design_decision_register.md`

### Canonical (mobile app v1)
The mobile-app-specific UX rules are maintained in the PM core docs:
- Core journeys + non-negotiable guardrails: `docs/pm/mobile_app/02_user_journey_maps.md`
- Language/accessibility/UI basics: `docs/pm/mobile_app/09_localization_and_accessibility.md`
- Offline baseline: `docs/pm/mobile_app/07_offline_mode_and_sync_specification.md`
- Notifications baseline: `docs/pm/mobile_app/08_notification_and_alert_strategy.md`
- Mobile implementation guidance: `docs/ux/jila_design_guide.md`

### Canonical (web portal)
The web portal UX rules and component specifications are maintained in:
- Canonical decisions + rationale: `docs/decision_registers/web_portal_decision_register.md`
- Component patterns + usage guidelines: `docs/design/02_component_patterns_spec.md`
- Design tokens (colors, typography, spacing): `docs/design/01_design_tokens_spec.md`

### What remains "global" here
- **Days remaining is an estimate**: always show freshness + confidence/data gaps; never imply false precision.
- **Avoid harm from bad estimates**: use conservative defaults when uncertain.
- **Low connectivity reality**: offline reads remain useful; user-entered data is never silently lost.
- **Ethical by default**: no dark patterns, no fake urgency.
- **Marketplace decisions are money decisions**: pricing transparency + reversible choices.
- **Just-in-time permissions**: ask only when benefit is obvious.

If you need to change any of these behaviors, update the PM docs above (and keep this shortlist consistent).
