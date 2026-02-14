---
title: Jila Website — Landing Page Screen Layout Spec (v1)
status: Draft (UI layout handoff)
last_updated: 2025-12-31
sources:
  - ../../architecture/jila_value_proposition_review_notes_aligned.md
  - ../mobile_app/05_mobile_app_prd.md
  - ../mobile_app/09_localization_and_accessibility.md
  - ../mobile_app/10_inclusive_design_guidelines.md
  - ../../ux/jila_design_guide.md
---

## Purpose
Provide a single, layout-oriented reference so a designer can create a complete **public landing page** for the Jila website:
- clear value proposition and narrative
- section-by-section layout regions and required content
- states (forms, errors), accessibility, and localization constraints
- deliverables checklist for design handoff (components, tokens, responsive behavior)

This is intentionally **layout-level** (structure + content requirements), not a visual UI spec.

## Value proposition of this documentation (why it exists)
This document helps us ship a high-quality landing page faster and with less drift:
- **Single source of truth for claims**: anchors marketing copy to canonical product narrative in `docs/architecture/jila_value_proposition_review_notes_aligned.md` so we don’t over-claim or contradict the product.
- **Design-ready structure**: gives a designer a modular page blueprint (hero → problem → solution → segments → trust → CTAs) without needing the app codebase.
- **Localization-first**: enforces Portuguese (pt-AO) primary and sets copy fields so we don’t hardcode English-first content.
- **Accessibility + performance guardrails**: avoids “pretty but unusable” outcomes (WCAG, motion reduction, byte budget / Lite Imperative).
- **Future-proof modularity**: sections are designed as reusable modules that can later become “Solutions” pages (Households / Sellers / Orgs) without rewriting the landing story.

## Confirmed scope decisions (this spec assumes)
- **This is the public marketing site** (unauthenticated) with links to:
  - Mobile app download / onboarding entry
  - Org portal login
  - “Request a demo / talk to us” lead capture (WhatsApp-first)
  - “Join waitlist” option (broad; does not assume a single segment)
- **We do not promise features beyond v1**:
  - No in-app payments, no chat, no live tracking, no surge pricing (aligns with `docs/pm/mobile_app/05_mobile_app_prd.md`).
- **Portuguese (pt-AO) first; English second** (non-negotiable).
- **Lightweight by default**: avoid heavy media backgrounds; vector-first illustrations (see “Lite Imperative” in `docs/ux/jila_design_guide.md`).
- **Geography framing**: copy should be **Angola-first** (not city-specific by default).

## Confirmed conversion + contact decisions (from PM)
- **CTAs**: we want all of these options available:
  - App downloads (“Get the app”)
  - Request a demo / meeting
  - Join waitlist
  - Calendar booking option (somewhere on the page)
- **Geography in copy**: keep it broad to **Angola**.
- **Contact channel**: **WhatsApp-first**, but the landing must support **Email and/or Phone** as alternatives.
- **Legal**: include placeholder links for Privacy/Terms (to be drafted).
- **Billing transparency**: landing page must include a **Subscriptions & pricing** module with clear tiers and honest “TBD/Contact us” where pricing values are not finalized.

## Global UX + content rules (non-negotiable)
- **Language**: Portuguese (pt-AO) first; English second. No hardcoded user-facing strings (copy must be externally manageable).
- **Accessibility**: WCAG AA baseline; usable with keyboard; clear focus states; do not rely on color alone; readable at 200% zoom.
- **Outdoor readability**: body text should target high contrast (see Solar Mode/contrast guidance in `docs/ux/jila_design_guide.md`).
- **Motion**: respect Reduce Motion; avoid animation-only meaning.
- **Trust posture**: avoid fake certainty, fake urgency, or implied guarantees. Be transparent about manual vs device mode.

### Typography rules (website, canonical)
- **IBM Plex Sans**:
  - Long-form body: `400`
  - Subheadings (H3–H4): `500`
  - Headings (H1–H2): `600` (no heavier)
  - Buttons / CTAs: `500`
  - Captions / footnotes: `400` (use size, not weight)
- **Silka Mono**:
  - Stats callouts: `500`
  - Numbers in hero sections: `500`
  - Small technical references: `400`

Rules:
- Silka Mono is a credibility accent, not decoration.
- Do not use IBM Plex Sans `300` or `700+` weights.
- Avoid casual italics.
- Do not switch fonts between product and website.
- Use **tabular numbers** for any aligned numeric content (KPIs, tables, stats).
- Format numbers locale-aware with thousand separators; units use a **thin space** (`12.4 L`, `3 m³`, `85 %`).
- Headings line-height must be `≤ 1.25`; labels `1.3–1.4`; body `1.45–1.6`.
- **No fallback stacks** for fonts (strict brand consistency).
- Letter-spacing: labels `+0.01em`, caps `+0.04–0.06em`, headings `-0.01em` optional, mono dense `+0.02em`.

## Page objectives (what the landing page must accomplish)
- Explain the problem in plain language: intermittent supply, high cost of emergency refills, low trust.
- Explain what Jila is (mobile-first reliability platform) and the three pillars:
  1) Monitor reservoirs (centered on “days of autonomy”)
  2) Connect buyers and sellers (marketplace)
  3) Generate trustworthy evidence (organizations, later stakeholders)
- Provide clear next steps per segment:
  - Households: “Start monitoring” (app)
  - Sellers: “Become a seller” (app)
  - Organizations: “Request a demo” (portal + ops)
- Communicate trust and safety principles (transparency, uncertainty, data integrity).

## Information architecture (public site)
### Header (sticky)
- Left: Jila logo
- Primary nav (keep as small as possible; target 5–6 items max):
  - “Como funciona” / “How it works”
  - “Dispositivo” / “Device” *(anchors to “Device bundles & ordering”)*
  - “Para famílias” / “For households”
  - “Para vendedores” / “For sellers”
  - “Para organizações” / “For organizations”
  - “Preços” / “Pricing” *(anchors to “Subscriptions & pricing” + “Device pricing”)*
  - “Contacto” / “Contact”
- Right actions:
  - Secondary link: “Entrar no Portal” / “Portal login”
  - CTA cluster (recommended):
    - Primary button: “Obter a app” / “Get the app”
    - Secondary button: “Pedir demonstração” / “Request a demo”
    - Tertiary link: “Lista de espera” / “Join waitlist”
- Mobile behavior:
  - hamburger menu with the same items + CTAs; keep tap targets ≥ 44px.

### Footer
- Columns:
  - Product: How it works, Households, Sellers, Organizations
  - Company: About (optional), Contact
  - Legal: Privacy, Terms (placeholders allowed)
  - Language switcher (pt-AO / EN)
- Bottom row:
  - © year + “Jila”
  - Social links only if we can maintain them (avoid dead links)

## Landing page layout (section-by-section)
Guidance format per section:
- **Goal**
- **Regions**
- **Required content fields (pt-AO + EN)**
- **Primary interactions**
- **Notes / constraints**

### 1) Above the fold (Hero)
**Goal**: Explain “what it is” in one glance + offer a clear **primary CTA**, while still making secondary conversion paths available (demo + waitlist).

**Regions**
- Hero headline + subheadline (left)
- CTA group (left):
  - Primary CTA
  - Secondary CTA
  - Tertiary link CTA (waitlist)
- Trust chips (small, 2–3 max) (left/below)
- Hero illustration (right or behind, but keep text legible)

**Required content fields**
- Headline (pt-AO, en)
  - Should reflect: reliability + time-to-empty concept (“dias de autonomia”)
- Subheadline (pt-AO, en)
  - Must mention mobile-first and low-connectivity friendliness (without making a technical promise)
- Primary CTA label + destination
- Secondary CTA label + destination
- Tertiary CTA label + destination (waitlist)
- Trust chips (pt-AO, en), examples (choose 2–3):
  - “Funciona mesmo com rede fraca” / “Works with unreliable connectivity”
  - “Modo manual ou com sensor” / “Manual or sensor-backed”
  - “Transparência e confiança” / “Trust-first monitoring”

**Primary interactions**
- Primary CTA click
- Secondary CTA click
- Language switch (global)

**Notes / constraints**
- Avoid guaranteed outcomes (“never run out”). Use risk-aware language.
- Visual language should align with “Blueprints of Life” (technical line art / cutaway tank concept).

### 2) Problem framing (Context: why this matters)
**Goal**: Show we understand the reality: intermittence, coping economy, high costs, uncertainty.

**Regions**
- Short headline + 3 problem cards (or a single vertical list on mobile)
- Optional contextual illustration (subtle background line art)

**Required content fields**
- Section title (pt-AO, en)
- Problem items (3 max), each with:
  - Icon/illustration reference
  - 1-line headline (pt-AO, en)
  - 1-line explanation (pt-AO, en)

**Notes / constraints**
- Do not overload with statistics unless we can cite sources on-site. If we include numbers, design must include a “source” footnote slot.

### 3) What Jila is (3 pillars)
**Goal**: Provide the crisp product definition from the canonical value prop.

**Regions**
- Section header
- Three pillar cards with icons/illustrations:
  1) Monitor
  2) Marketplace connection
  3) Evidence/visibility

**Required content fields**
- Section title + 1–2 line summary (pt-AO, en)
- Per pillar:
  - Title (pt-AO, en)
  - 1–2 lines description (pt-AO, en)
  - “Learn more” anchor target (optional, within page)

**Notes / constraints**
- Keep language aligned to:
  - “days of autonomy” framing
  - manual/community mode inclusion (not a “rich person’s app”)
  - organizations + portal existence without promising Phase B/C dashboards on v1 landing.

### 4) How it works (simple 4-step sequence)
**Goal**: Make the system feel engineered, understandable, and trustworthy.

**Regions**
- Stepper (4 steps) with line-art visuals (“Ikea/Dyson manual style”)
- Optional “Modes” toggle: Manual vs Sensor-backed (content changes but layout stays)

**Required content fields**
- Section title (pt-AO, en)
- Steps (4), each:
  - Step label (pt-AO, en)
  - 1 short guidance line (pt-AO, en)
  - Illustration reference
- Modes copy (if included):
  - Manual mode summary (pt-AO, en)
  - Sensor mode summary (pt-AO, en)

**Notes / constraints**
- No paragraphs; use minimal copy; illustration-led.
- Respect Reduce Motion (step transitions must not require animation).

### 5) Segment split (choose your path)
**Goal**: Let visitors self-identify quickly and get the right CTA.

**Regions**
- Three segment cards:
  - Families/households
  - Sellers (tanker/fixed)
  - Organizations (multi-site)
- Each card has: short benefits list + primary CTA

**Required content fields**
- Segment title (pt-AO, en)
- 2–3 bullet benefits (pt-AO, en)
- CTA label + destination

**Recommended CTA destinations (design placeholders)**
- Households: “Começar a monitorizar” → app onboarding / store
- Sellers: “Tornar-me vendedor” → app onboarding / seller setup
- Organizations: “Pedir demonstração” → lead form section (on-page) or dedicated page

### 6) Trust & safety (why you can rely on it)
**Goal**: Address low-trust environment concerns: transparency, uncertainty, data integrity.

**Regions**
- Trust principles list (3–5)
- Optional: “What we won’t do” micro-section (2 items) to signal ethics

**Required content fields**
- Section title (pt-AO, en)
- Trust principles (choose 3–5), each with icon + 1-line:
  - “Mostramos quando os dados estão antigos (Última atualização)” (freshness)
  - “Sem truques: preços claros, ações claras” (marketplace transparency)
  - “Modo manual quando não há sensor” (inclusion)
  - “Respeito pela privacidade” (privacy posture; keep non-legal)
- Optional “We won’t” (pt-AO, en):
  - no fake urgency
  - no hidden fees (only if true for v1)

### 7) Proof / credibility (lightweight)
**Goal**: Create trust by showing verifiable sponsors, recognition, and media presence (without exaggeration).

**Regions**
- Sponsors row (logos)
- Recognition / awards card(s)
- Media mentions list (logos or publication cards)
- Optional: short “Why it matters” trust statement (1–2 lines max)

**Sponsors (confirmed)**
- Microsoft for Startups
- Google for Startups
- AWS Activate

**Recognition (confirmed)**
- Earthshot Prize: nominated twice in a row; running for 2026 version

**Media presence (confirmed)**
- Web Summit (presence/participation)
- Press article (newspaper / publication) — link required

**Required content fields**
- Section title (pt-AO, en)
- Sponsors:
  - Each sponsor logo asset (SVG/PNG) + alt text (accessibility)
  - Optional outbound link to sponsor program page (not required, but recommended)
- Recognition:
  - Award/program name + year(s)
  - Short, precise claim text (pt-AO, en)
  - Link to proof/announcement page (required if we claim nomination)
- Media:
  - Event/publication name
  - Short descriptor (e.g., “Featured at Web Summit” / “Article”)
  - Link (required)

**Notes / constraints**
- Do not include any logo or award claim without a linkable reference in production content.
- Avoid absolute claims like “backed by” unless the sponsor program language supports it; use “Supported by” / “Participant in”.
- Keep the section scannable; do not bury the value proposition under logos.

### 8) Subscriptions & pricing (transparent, conservative)
**Goal**: Be explicit about subscription tiers and what they unlock, without inventing prices. This is a trust-critical section.

**Regions**
- Section header + short disclaimer line
- 3-tier comparison (cards or table):
  - Tier 1: Monitor
  - Tier 2: Protect
  - Tier 3: Pro
- Each tier includes:
  - “Best for” line
  - 3–6 bullet features (plain-language)
  - Pricing display slot (can be “TBD”)
  - CTA (WhatsApp contact or demo request)
- “Have questions?” micro-panel:
  - WhatsApp CTA (primary)
  - “Book a meeting” calendar CTA (secondary)

**Required content fields**
- Section title (pt-AO, en)
- Short disclaimer (pt-AO, en): honest about pricing being subject to change / confirm on WhatsApp
- For each tier:
  - Display name (pt-AO, en)
  - Internal key (for reference only): `plan_id = monitor|protect|pro` (do not show to users)
  - “Best for” (pt-AO, en)
  - Feature bullets (pt-AO, en)
  - Price label + value slot:
    - currency: AOA (Angolan Kwanza) by default
    - value may be `TBD` until finalized
- FAQ link anchor: “Perguntas frequentes” / “FAQ” (optional; can be a small accordion)

**Notes / constraints**
- Canonical source of tier identifiers is `docs/architecture/jila_api_backend_data_models.md` (`plan_id: monitor|protect|pro`).
- Canonical mechanism for gating is `plans.config.features` (see `docs/architecture/jila_api_backend_decision_register.md` D-023).
- If we publish numeric prices later, the design must support:
  - monthly price display
  - “per site”/“per device” qualifiers (if that becomes true)
  - “Contact us” fallback when pricing is not public

### 9) Device bundles & ordering (pricing + stock-aware purchase funnel)
**Goal**: Present device pricing transparently (one-time purchase) and support an ordering flow that either completes purchase when in stock or routes users to the waitlist when out of stock.

**Regions**
- Section header + “starting from” price callout
- Bundle cards grid (each with a photo):
  - Base device bundle
  - Power options as add-ons / variants (Solar vs Direct-to-electricity)
- What’s included (simple checklist)
- Ordering module:
  - quantity selector (optional)
  - delivery region selector (optional; Angola regions) *(if needed later)*
  - primary CTA: “Comprar agora” / “Buy now”
  - secondary CTA: “Entrar na lista de espera” / “Join waitlist”
- Stock state banner (non-alarming, factual)

**Bundles (v1 website)**
- Base bundle:
  - **Starting at 150 000 Kz** (Angolan Kwanza; display as `Kz` and optionally `AOA`)
  - Includes:
    - Jila device
    - **Standalone water measurement sensor** (always included)
- Power options (affect price; copy should stay minimal):
  - **Solar panel**: for remote use cases / where wiring to electricity is not feasible.
  - **Direct-to-electricity**: available option. *(Do not list “advantages” yet; keep as a simple variant.)*

**Required content fields**
- Section title (pt-AO, en)
- Starting price string (pt-AO, en) (must support “from” / “starting at” wording)
- Per bundle / variant card:
  - Card title (pt-AO, en)
  - Price display slot (Kz/AOA)
  - 1–3 bullet highlights (pt-AO, en)
  - Photo asset slot (required) + alt text
  - CTA label (pt-AO, en)
- Stock messaging copy (pt-AO, en)

**Ordering flow states (must be designed)**
- Stock unknown (initial): show neutral loading state; do not block browsing bundles.
- In stock:
  - Primary CTA proceeds to an ordering step (embedded modal/section or dedicated page).
- Out of stock:
  - Primary CTA routes to **waitlist** (prefilled with selected bundle/variant).
  - Explicit message: “Sem stock — vamos avisar quando estiver disponível.” / “Out of stock — we’ll notify you.”
- Submit success: show confirmation + what happens next.
- Submit failure: show error banner + retry, preserve user input.

**Notes / constraints**
- **Reservation (DECIDED)**: this is a **reservation flow**, not an online checkout. There is **no online payment** at order time.
- “Starting at 150 000 Kz” should include a small disclaimer slot:
  - pricing may change; add-ons (solar / installation / delivery) may affect the total.
- Stock source/system is TBD; design should not assume real-time inventory accuracy—be clear and conservative.
- Payment options (must be explicit during ordering):
  - **Option A (default)**: **Pay on delivery** after we confirm delivery time.
  - **Option B (trial deposit)**: pay **30% upfront** to try the device for a limited period; then either return it or pay the remaining balance.

#### 9.1 Reservation flow (no online payment)
**Required UX copy points (must appear before submit)**
- “Sem pagamento online.” / “No online payment.”
- “Depois de reservar, contactamos com o prazo de entrega.” / “After you reserve, we contact you with the delivery time.”
- “Pagamento na entrega.” / “Pay on delivery.”

**Reservation form (minimum)**
- Selected bundle/variant (prefilled from the bundle card)
- Contact details (reuse the same contact rule as lead capture: WhatsApp OR Phone OR Email)
- Delivery location (Angola; city/municipality freeform or dropdown — design choice)
- NIF (optional; recommended for orgs)
- Notes (optional)

**States**
- Submitting reservation
- Reservation submitted (success) + “what happens next”
- Failure + retry (preserve inputs)

#### 9.2 Trial deposit option (30/70 split; transparent)
**Intent**: lower adoption risk while staying honest about terms.

**User-facing rules (must be shown as a clear checklist)**
- Pay **30% upfront** to start the trial.
- Trial duration: **[2–3 weeks]** (exact duration to be finalized; copy must use the configured value).
- During the trial:
  - No subscription fee is charged.
- If the user does not want to continue:
  - We take the device back (return flow and condition policy to be defined separately).
- If the user wants to keep the device:
  - Pay the remaining **70%**.
  - Then the subscription rules apply after a free period:
    - Free period during trial is granted.
    - Additional “bonus” free subscription time after full payment is granted (exact policy/duration TBD; design must support a configurable value).

**Notes / constraints**
- This is a reservation-first website. If/when “30% upfront” is enabled, the ordering UI still must not imply online checkout unless we have a real payment mechanism.
- The spec intentionally does not define refund/return condition details; the design must include a link/slot to “Trial terms” content.

### 10) Lead capture / contact (WhatsApp-first + calendar booking)
**Goal**: Convert demo/waitlist interest using WhatsApp as the default channel, with a calendar booking option.

**Regions**
- Left: short pitch + what happens next (3 bullets)
- Right: form card
- Optional: calendar booking embed/module (can be below or alongside the form)

**Form fields (recommended, WhatsApp-first with alternatives)**
- Name (required)
- Contact method (required):
  - WhatsApp number
  - Phone number
  - Email
  - UX rule: default selection is **WhatsApp** (fastest in Angola), but users may choose Email/Phone instead.
- WhatsApp number (conditionally required when WhatsApp is selected)
  - Prefer E.164 formatting in capture (or capture local + normalize server-side later)
- Phone number (conditionally required when Phone is selected)
  - If the user provides WhatsApp, do not force a separate phone field (avoid duplicate inputs)
- Email (conditionally required when Email is selected)
- Validation rule (non-negotiable): at least **one** contact channel must be provided:
  - WhatsApp OR Phone OR Email
- NIF (optional; recommended for organizations)
- “I am” selector: Household / Seller / Organization
- Message (optional)
- Consent checkbox (if required by legal) + links to Privacy/Terms (placeholders allowed)

**States**
- Idle
- Submitting
- Success (clear next steps, not just “Thanks”)
- Error (field-level + banner; preserve input)

**Notes / constraints**
- Include a “Falar no WhatsApp” / “WhatsApp us” CTA even outside the form (for ultra-low friction).
- Calendar booking:
  - Provide a “Marcar reunião” / “Book a meeting” CTA and an embed slot (provider TBD; e.g., a calendar scheduling widget).
  - Must degrade gracefully if the widget fails to load (show link-only fallback).

### 11) Final CTA band
**Goal**: Last chance conversion with one clear action.

**Regions**
- Bold headline + one primary CTA + one secondary link (portal login)

## Responsive behavior (must be designed)
- Mobile-first layout (single column).
- Tablet: two-column where appropriate (hero, contact).
- Desktop: multi-column with strict maximum text width for readability.
- Keep primary CTA visible within first screen on common devices.

## Accessibility requirements (web)
- Keyboard navigation: visible focus outline on all interactive elements.
- Semantic headings and landmarks (header/nav/main/footer).
- Form labels + inline error association; no placeholder-only labels.
- Contrast: meet WCAG AA minimum; avoid “light grey on white”.
- Icons are never the only meaning; pair with labels.
- Reduce Motion: disable non-essential animations and parallax.

## Localization requirements (pt-AO + EN)
- All landing content must exist in:
  - pt-AO (default)
  - English
- Avoid idioms; keep sentences short.
- Allow longer Portuguese strings without breaking layout.
- Date/time formatting only if we show them (generally avoid dynamic dates on landing).

## Performance constraints (Lite Imperative — web interpretation)
- Vector-first illustrations/icons; avoid video backgrounds.
- Images must be optimized and not block first paint.
- Defer non-critical scripts; keep analytics lightweight.

## Analytics + measurement (recommended event map)
The designer should account for instrumentation (no UI required beyond stable ids):
- `landing_view`
- `cta_primary_click` (with `cta_id`, `section`)
- `cta_secondary_click` (with `cta_id`, `section`)
- `cta_waitlist_click` (with `section`)
- `cta_portal_login_click`
- `cta_whatsapp_click` (with `section`)
- `calendar_open` (with `section`)
- `pricing_view` (when pricing section enters viewport)
- `pricing_tier_select` (with `plan_display_name`)
- `device_pricing_view` (when device section enters viewport)
- `device_bundle_select` (with `bundle_id`, `power_option`)
- `device_order_start` (with `bundle_id`, `power_option`)
- `device_stock_status` (with `status=unknown|in_stock|out_of_stock`)
- `device_reservation_submit_start`
- `device_reservation_submit_success`
- `device_reservation_submit_error`
- `device_payment_option_select` (with `option=pay_on_delivery|trial_deposit`)
- `device_trial_terms_open`
- `device_waitlist_submit_success`
- `device_waitlist_submit_error`
- `segment_select` (household/seller/org)
- `lead_form_submit_start`
- `lead_form_submit_success`
- `lead_form_submit_error`
- `language_switch` (pt-AO/en)

## Designer handoff checklist (deliverables)
- Page-level:
  - Desktop + tablet + mobile layouts
  - Sticky header + mobile menu behavior
  - Footer layout
- Components (reusable):
  - Primary/secondary buttons
  - Segment card
  - Pillar card
  - Stepper item
  - Trust principle row
  - Form fields + validation states + banner error + success state
- Illustration guidance:
  - Hero illustration concept (cutaway tank / engineered reliability)
  - 4-step “How it works” line art set (Blueprints of Life)
- Tokens:
  - Spacing scale, radius scale, typography hierarchy
  - Focus styles + hover/pressed states
- Copy sheet:
  - pt-AO + EN strings for every required field in this spec (even if placeholder copy is used initially)

## Appendix A — Wireframe outline (single-page view)
This is a linear outline a designer can translate into wireframes quickly:

1) Header (sticky): Logo | Nav | Portal login | Get app | Request demo | Waitlist  
2) Hero: Headline + subheadline + CTA group + trust chips + illustration  
3) Problem framing: 3 problem cards  
4) What Jila is: 3 pillars (Monitor / Marketplace / Evidence)  
5) How it works: 4-step sequence (+ optional mode toggle)  
6) Choose your path: Households / Sellers / Organizations cards with CTAs  
7) Trust & safety: principles (freshness, transparency, inclusion, privacy posture)  
8) Proof / credibility: sponsors + awards + media mentions (with links)  
9) Subscriptions & pricing: tier cards/table + “questions” panel + WhatsApp + calendar CTA  
10) Device bundles & ordering: bundle cards + photos + stock-aware purchase/waitlist funnel  
11) Contact/lead capture: form + calendar option + success/error states  
12) Final CTA band  
13) Footer: Product | Company | Legal | Language

## Appendix B — Starter copy set (safe defaults; pt-AO primary)
This copy is intentionally conservative and aligned to:
- `docs/architecture/jila_value_proposition_review_notes_aligned.md`
- `docs/pm/mobile_app/05_mobile_app_prd.md`

Design should treat this as editable content, not hardcoded UI.

### Hero (Option set)
**Option 1 (reliability + time framing)**
- pt-AO headline: “Saiba quantos dias de água ainda tem.”
- pt-AO subheadline: “Jila ajuda famílias e organizações em Angola a monitorizar reservatórios, planear recargas e tomar decisões com confiança — mesmo quando a conectividade é fraca.”
- en headline: “Know how many days of water you have left.”
- en subheadline: “Jila helps households and organizations in Angola monitor reservoirs, plan refills, and make confident decisions — even with unreliable connectivity.”

**Option 2 (avoid emergency)**
- pt-AO headline: “Menos emergência. Mais previsibilidade.”
- pt-AO subheadline: “Monitorização manual ou com sensor, centrada em ‘dias de autonomia’ para evitar surpresas.”
- en headline: “Fewer emergencies. More predictability.”
- en subheadline: “Manual or sensor-backed monitoring, centered on ‘days of autonomy’ to avoid surprises.”

**CTA set (landing default)**
- Primary CTA:
  - pt-AO: “Obter a app”
  - en: “Get the app”
- Secondary CTA:
  - pt-AO: “Pedir demonstração”
  - en: “Request a demo”
- Tertiary CTA (link):
  - pt-AO: “Lista de espera”
  - en: “Join the waitlist”

**Secondary CTA (recommended)**
- pt-AO: “Como funciona”
- en: “How it works”

### Problem framing (3 cards)
- pt-AO titles:
  - “A água nem sempre chega.”
  - “Recargas de emergência custam caro.”
  - “É difícil confiar nos dados.”
- en titles:
  - “Water doesn’t always arrive.”
  - “Emergency refills are expensive.”
  - “It’s hard to trust the information.”
- Guidance line (shared pattern):
  - pt-AO: “Jila torna a situação visível e ajuda a agir cedo.”
  - en: “Jila makes it visible and helps you act early.”

### 3 pillars (What Jila is)
- pt-AO:
  1) “Monitorizar reservatórios” — “Veja nível, saúde do sensor (quando existir) e a última atualização.”
  2) “Conectar compra e venda” — “Quando precisa de recarga, encontre opções e avance com transparência.”
  3) “Gerar evidência confiável” — “Para organizações: visibilidade por site e histórico útil para planeamento.”
- en:
  1) “Monitor reservoirs” — “See level, sensor health (when available), and last updated.”
  2) “Connect buyers and sellers” — “When you need a refill, find options and move forward transparently.”
  3) “Generate trustworthy evidence” — “For organizations: site-level visibility and history for planning.”

### Trust & safety (principles)
- pt-AO:
  - “Mostramos quando os dados estão antigos (‘Última atualização’).”
  - “Sem promessas falsas: distinguimos modo manual e modo com sensor.”
  - “Transparência nas decisões: ações claras e estados claros.”
  - “Privacidade por padrão.”
- en:
  - “We show when data is old (‘Last updated’).”
  - “No false certainty: we distinguish manual vs sensor-backed mode.”
  - “Transparent decisions: clear actions and clear states.”
  - “Privacy by default.”

### Device (starter copy)
- pt-AO:
  - Headline: “Dispositivo Jila (compra única)”
  - Price line: “A partir de 150 000 Kz”
  - Included: “Inclui sempre um sensor de medição de água.”
  - Power options:
    - “Opção Solar: para locais remotos ou sem ligação elétrica.”
    - “Opção Ligação à eletricidade: disponível.”
  - Stock messaging:
    - “Com stock: pode encomendar agora.”
    - “Sem stock: entre na lista de espera e avisamos quando estiver disponível.”
- en:
  - Headline: “Jila device (one-time purchase)”
  - Price line: “Starting from 150,000 Kz”
  - Included: “Always includes a standalone water measurement sensor.”
  - Power options:
    - “Solar option: for remote sites or where wiring isn’t feasible.”
    - “Mains power option: available.”
  - Stock messaging:
    - “In stock: you can order now.”
    - “Out of stock: join the waitlist and we’ll notify you.”

### Lead capture (what happens next)
- pt-AO bullets:
  - “Respondemos em [24–48h].”
  - “Confirmamos o seu caso de uso (família, vendedor ou organização).”
  - “Partilhamos os próximos passos.”
- en bullets:
  - “We reply within [24–48h].”
  - “We confirm your use case (household, seller, or organization).”
  - “We share next steps.”



