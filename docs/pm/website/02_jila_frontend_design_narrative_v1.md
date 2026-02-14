---
title: Jila — website
status: Draft
scope: Cross-surface (marketing website + mobile app + web portal)
last_updated: 2026-02-14
purpose: Story-first creative brief for frontend designers — the emotional arc, brand voice, and experience narrative that ties all three Jila surfaces together
---

# Jila — Website Design Narrative Brief

## How to use this document

This document answers a different question: **what should the designer feel when they create this product?**

Read this before opening Figma. It gives you the story, the emotional beats, and the design personality that should guide every creative decision across Jila's three surfaces: the marketing website, the mobile app, and the web portal.

---

## Part 1 — The World Jila Exists In

### The reality

In Luanda, Angola, water is not a utility you forget about. It is a daily negotiation.

Only about one-third of households have a direct connection to the piped network. That network loses roughly half its treated water before it reaches anyone. When it does arrive, it arrives unpredictably — sometimes for a few hours, sometimes not for days. The rest of the city depends on a parallel economy: tanker trucks, standpipes, boreholes, and informal sellers operating without coordination or transparency.

This creates a **coping economy**: families stockpile water in rooftop tanks without knowing how long it will last. When they run out, they call whoever answers — often paying 40 to 50 times the subsidized tariff for an emergency refill. Sellers drive around guessing where demand is, burning fuel on wasted trips. Organizations with dozens of sites have no unified view of which locations are at risk. Funders and utilities lack the granular, independent data to know whether interventions actually improved anything.

### The emotional landscape

The designer should internalize three emotional truths:

1. **Anxiety of the unknown.** Maria does not know if her tank will last until Friday. She checks by tapping the side or climbing to the roof. The number she gets is a guess. Her decisions — whether to let the children bathe, whether to call a seller now or wait — are made under genuine uncertainty. *The app's job is to replace anxiety with a calm, honest answer.*

2. **The cost of emergencies.** When Carlos the seller gets a panic call at 2 AM, both he and the buyer know the price will be high. Emergency refills are where the most money is lost and the most trust eroded. *The platform's job is to make refills predictable, not desperate.*

3. **The invisibility of the problem.** Intermittent water supply is chronic but invisible to anyone not living it. There is no dashboard showing which neighborhoods went dry this week. No evidence pack proving that a new pump station actually changed outcomes. *Jila's job is to make the invisible measurable.*

### The design tension

Jila lives at the intersection of **engineered precision** and **human vulnerability**. The product must feel technically competent — like infrastructure, like a gauge, like something an engineer would trust — while simultaneously being gentle enough for someone who may never have used a smartphone app before. This tension is the creative challenge. The answer is not to simplify until there is nothing left, nor to over-engineer until it becomes intimidating. The answer is **calm engineering**: precise, honest, and kind.

---

## Part 2 — The Jila Promise

### Core identity

Jila is a **mobile-first water reliability platform** for markets with intermittent water supply.

It is not a utility app (it does not replace the water company). It is not a delivery app (it does not dispatch drivers). It is not a social network. It is a **reliability layer** — a system that sits on top of whatever water infrastructure exists (pipes, trucks, standpipes, buckets) and makes it visible, predictable, and accountable.

### The central metaphor: "Days of autonomy"

The single most important design concept in Jila is **"days of autonomy"** — how many days of water a household or site has remaining at current consumption.

This is the pivot from liters (a technical unit most people do not think in) to **time** (a concept everyone understands). "You have 3 days of water" is immediately actionable in a way that "You have 1,200 liters" is not.

But this number is an **estimate**. It depends on household size, consumption patterns, data freshness, and whether readings come from a sensor or a manual input. The designer must treat this number with respect:
- Always show it with a **freshness timestamp** ("Last updated: 14:32")
- Always show **confidence** (high / medium / low) or a range when confidence is low ("~1–2 days")
- Never imply false precision. "3 days" is better than "3.2 days" for a manual reading with low confidence.
- Round **down**, not up. If the estimate is 2.7 days, display "2 days." Under-promising is safer than over-promising when running out of water means your children do not drink.

### Three pillars as narrative acts

Jila's value unfolds in three acts, and the designer should think of them as a progression — not just three equal boxes on a page:

**Act 1 — Monitor.** "Know what you have."
This is where trust begins. Before Jila, you guessed. Now you see a number, a timestamp, and a confidence level. The tank visualization — a cutaway view showing water level — is the visual anchor of this act. It should feel like looking through glass at something real.

**Act 2 — Connect.** "Get what you need."
When monitoring reveals that you are running low, the marketplace connects you to a seller. This is not a shopping experience — it is a logistics handoff. The emotional tone is practical, not promotional. Prices are transparent. Delivery is confirmed by both parties. The goal is to make refills routine, not heroic.

**Act 3 — Prove.** "Show what happened."
For organizations, the data collected in Acts 1 and 2 becomes evidence: exportable reports showing intermittence patterns, refill frequency, coping costs, and intervention outcomes. This is Jila's long-term strategic value — turning household-level monitoring into infrastructure-level intelligence.

### Trust posture: radical honesty

In a market where people have been burned by unreliable services, false promises, and hidden costs, Jila's brand position is **radical honesty**:

- **We show when data is old.** Every reading has a "Last updated" timestamp. If the data is stale, the interface says so — visually (desaturation / "ghost" treatment) and in text.
- **We distinguish manual from sensor.** A reading entered by hand and a reading from a calibrated ultrasonic sensor have different confidence levels. The UI makes this clear without making manual users feel like second-class citizens.
- **We say "we don't know" when we don't know.** If the estimate has low confidence, we say so. We show a range instead of a point value. We never fabricate certainty.
- **We never use fake urgency.** No countdown timers. No "only 2 sellers left!" No dark patterns. If the water is low, the UI communicates urgency through clear, calm signals (color + icon + label), not through manipulation.

### Design personality: "Calm engineering"

If Jila were a physical object, it would be a well-made industrial gauge — the kind mounted on a water treatment plant, with clear markings, no decorative flair, and an obvious reading that anyone walking by can understand in two seconds.

The personality is:
- **Precise**, not flashy
- **Honest**, not aspirational
- **Industrial**, not playful
- **Respectful**, not patronizing
- **Calm**, not urgent

The closest analogies in consumer product design: the instrumental clarity of a Braun alarm clock; the illustrated instruction language of an IKEA assembly manual; the functional density of a Garmin marine GPS.

---

## Part 3 — The Marketing Website (jila.ai)

### Purpose

The website is the **first impression**. Most visitors will arrive knowing nothing about Jila. Some will be households looking for help. Some will be organizations evaluating a deployment. Some will be funders or press checking credibility. The website must serve all three — clearly, quickly, and honestly.

### The visitor's emotional journey

The page is a single scrolling narrative. Each section moves the visitor through a deliberate emotional arc:

#### 1. Recognition (Hero)
**Visitor feels:** "This is my problem."

The hero should hit the visitor with the problem they already know. The headline centers on time — "Saiba quantos dias de água ainda tem" ("Know how many days of water you have left"). Not liters, not technology, not "smart water" — just the question that keeps Maria awake at night.

The illustration should be the first taste of "Blueprints of Life": a cutaway tank showing a water level, with clean technical line art. It says: *this is engineered, this is real, this is not another app that promises the world.*

Two to three trust chips sit below the headline — small, factual, non-promotional:
- "Works with unreliable connectivity"
- "Manual or sensor-backed"
- "Trust-first monitoring"

Three CTAs are visible: Get the app (primary), Request a demo (secondary), Join waitlist (tertiary link).

#### 2. Validation (Problem framing)
**Visitor feels:** "Someone understands what I deal with."

Three cards. Three truths. No statistics unless we can cite sources on the page.

- "A água nem sempre chega." — Water does not always arrive.
- "Recargas de emergência custam caro." — Emergency refills are expensive.
- "É difícil confiar nos dados." — It is hard to trust the data.

The tone here is empathetic, not dramatic. We are naming the reality, not exploiting it. No stock photos of drought. The visual language is the same clean line art — subtle, factual, dignified.

#### 3. Hope (What Jila is — three pillars)
**Visitor feels:** "There is a system that could help."

Three pillar cards introduce Monitor, Connect, Prove. Each gets a one-line title and a one-to-two-line description. The copy stays grounded:

- "Monitor reservoirs" — "See level, sensor health (when available), and last updated."
- "Connect buyers and sellers" — "When you need a refill, find options and move forward transparently."
- "Generate trustworthy evidence" — "For organizations: site-level visibility and history for planning."

No promises of outcomes. No "never run out again." Just capability, stated plainly.

#### 4. Clarity (How it works)
**Visitor feels:** "I understand how it works — it feels engineered, not magic."

A four-step visual sequence in the "Ikea manual" illustration style — white line drawings on midnight navy, numbered steps, minimal text. The visitor should be able to understand the flow without reading a single word.

An optional Manual / Sensor toggle shows that the system works both ways — this is important for inclusion.

#### 5. Identity (Choose your path)
**Visitor feels:** "I see myself in this."

Three segment cards: Households, Sellers, Organizations. Each card has two to three bullet benefits and a specific CTA:

- Households → "Começar a monitorizar" → app store
- Sellers → "Tornar-me vendedor" → app store / seller onboarding
- Organizations → "Pedir demonstração" → lead form on-page

The visitor self-selects. The product is for them specifically, not for "everyone."

#### 6. Trust (Safety principles)
**Visitor feels:** "They are honest about what they can and can't do."

Three to five trust principles with icons:

- "We show when data is old."
- "No false certainty: we distinguish manual vs sensor-backed."
- "Clear actions and clear states."
- "Privacy by default."

Optional "What we will not do" micro-section: no fake urgency, no hidden costs. This section is unusual for a product landing page — most competitors would hide limitations. Jila leads with them. In a low-trust market, this is a competitive advantage.

#### 7. Credibility (Proof)
**Visitor feels:** "Real backers, real recognition."

Sponsor logos (Microsoft for Startups, Google for Startups, AWS Activate), Earthshot Prize nomination, Web Summit presence. Every claim must have a clickable reference link. No logos without proof.

The tone is understated: "Supported by" rather than "Backed by." Scannable, not boastful.

#### 8. Commitment (Pricing + Device)
**Visitor feels:** "I know what it costs and how to start."

**Subscription tiers:** Monitor (free) / Protect (paid) / Pro (premium). Honest about TBD pricing where values are not finalized. Each tier shows "Best for," feature bullets, and a CTA.

**Device bundles:** Starting from 150,000 Kz. Always includes a standalone water measurement sensor. Solar and mains power options. This is a **reservation flow, not online checkout** — no payment at order time. The UX must be explicit: "No online payment. After you reserve, we contact you with the delivery time. Pay on delivery."

The 30/70 trial deposit option (pay 30% to try, return or pay the rest) must be explained as a clear checklist, not buried in fine print.

#### 9. Action (Contact / Lead capture)
**Visitor feels:** "I am ready to take the next step."

WhatsApp-first contact form. The default contact method is WhatsApp — this is how Angola communicates. Email and phone are alternatives, not replacements.

Three bullets tell the visitor what happens next:
- "We reply within 24–48 hours."
- "We confirm your use case."
- "We share next steps."

A calendar booking option sits alongside or below the form for those who prefer scheduled calls.

### Website design directives summary

| Directive | Rationale |
|---|---|
| Angola-first, Portuguese-first | Not an afterthought translation; pt-AO is the default |
| WhatsApp as gravity center | Primary communication channel in Angola |
| "Blueprints of Life" illustrations | Technical line art builds trust; lightweight for data-costly networks |
| IBM Plex Sans (narrative) + Silka Mono (numbers) | Credibility and clarity without decorative type |
| Reservation model (no online checkout) | Honest about the purchase process |
| Vector-first, lightweight assets | Respect data costs; avoid heavy media |
| No guaranteed outcomes in copy | Risk-aware language only; "avoid surprises" not "never run out" |

---

## Part 4 — The Mobile App

### Purpose

The app is the **daily companion**. If the website is where you decide to trust Jila, the app is where you live with it — checking your water level in the morning, placing an order when you are low, finding a standpipe in an unfamiliar neighborhood, updating a site reading for your organization.

The app is a single codebase (React Native) that adapts its experience based on the user's role. The same app serves all four personas. The navigation stays consistent — four bottom tabs (Home, Marketplace, Map, Profile) — but what appears under "Home" changes based on who you are.

### Experience Mode 1 — Maria's World (Household)

**Core emotion:** Peace of mind.

Maria opens the app to a screen dominated by her reservoir. The tank visualization — a cutaway rendered in the "glass and steel" material language — shows the current water level as a percentage and in liters, with a prominent "days remaining" estimate and a "Last updated" timestamp in Silka Mono.

This is the **emotional anchor** of the entire app. Everything else radiates outward from this screen.

**The tank visualization ("Fluid Reality")**
- A subtle water surface animation inside the tank (viscous, not cartoon). Tilting the phone changes the surface angle slightly — a cognitive anchor that says "this is real water in a real container."
- When offline or stale, the tank applies a "ghost" treatment: desaturated, with the timestamp clearly marked. The data stays visible. The app never blanks to a spinner. It says: "This is what I last knew. Let me try again."
- Numbers are canonical — the visualization reinforces but never replaces the numeric reading.
- On devices with Reduce Motion enabled, the animation is disabled; a static high-contrast fill render takes its place.

**"Days remaining" — the heartbeat metric**
- Displayed prominently, always with freshness ("Last updated: 14:32") and confidence (HIGH / MEDIUM / LOW).
- When confidence is LOW, show a range ("~1–2 days") and a gentle prompt to add more data (household size, manual reading).
- Rounds down. Always conservative.

**The Replenishment Card**
- When Maria's level drops below 20%, a non-blocking card slides up from the bottom (not a modal, not a popup — a card).
- It pre-fills a suggested volume and surfaces the best-default seller option.
- One tap leads to a pre-filled order confirmation. The total cost is visible before she commits.
- The card is visually urgent (warm colors, clear iconography) but never manipulative — no fake timers, no "only 2 sellers available."

**Manual-first, sensor as upgrade**
- Maria may not have a Jila device. Her first experience is likely manual: she adds her tank dimensions, enters a reading by slider, and sees an estimate. The app must make this feel complete, not provisional. The sensor upgrade path exists but is never framed as "you are missing out."

### Experience Mode 2 — Carlos's World (Seller)

**Core emotion:** Efficiency and control.

Carlos opens the app to a seller dashboard. The dominant element is his **availability toggle** — a large, obvious on/off control. When he is ON, he is visible on the marketplace. When he is OFF, he is not. No ambiguity.

**Incoming orders are the heartbeat.** When a new order arrives, the notification must be hard to miss — push notification with a distinctive sound/vibration pattern, and a prominent card in the app. Carlos's livelihood depends on not missing an order while driving.

**Pricing is his.**
Carlos sets his own prices via volume tiers and a flat delivery fee. The pricing interface is a step-by-step wizard — not a spreadsheet. He should be able to update prices in under a minute on a hot afternoon, one-handed, glancing at his phone at a traffic stop.

**Tangible feedback:** Accepting an order gives a strong haptic "thud" and a clear confirmation card. Rejecting gives a different haptic and asks for a one-tap reason. Every action has an immediate, physical-feeling response.

### Experience Mode 3 — Joana's World (Community Seeker)

**Core emotion:** Discovery and relief.

Joana opens the app — or the marketplace section of the website — to a **map of supply points** near her. She does not have an account. She does not need one to browse.

The map shows community supply points (standpipes, boreholes, kiosks) with icons that encode type (silhouette) and availability (color + icon, never color alone). She taps a marker and sees:
- Name and type
- Operational and availability status
- Verification status (VERIFIED / PENDING_REVIEW — trust signal)
- Last updated timestamp (freshness — trust signal)
- One-tap "Directions" that opens her native maps app

**The map is a trust surface.** Every marker carries its own credibility metadata. Joana should be able to look at a marker and quickly assess: "Is this information fresh? Is it verified? Can I rely on it?" If the data is old, the UI says so. If it is unverified, the UI says so. No false confidence.

**Performance matters.** Joana may be on a 2G connection with an older Android device. The map must load fast, use lightweight tiles, and minimize overlays. Discovery must work even if map tiles are slow — a list view is always available as a fallback.

### Experience Mode 4 — Antonio's World (Org Operator)

**Core emotion:** Accountability and clarity.

Antonio joined via an org invite link. His app opens directly to his organization's view — not a personal dashboard, but his assigned sites. He sees:
- A list of sites with quick risk indicators (level state, freshness, alerts)
- The ability to drill into any site's reservoirs
- A fast manual reading submission flow (find reservoir → enter level → confirm → done in under 60 seconds)

**Every update Antonio makes is auditable.** The UI should subtly reinforce this: his name is attached to the reading, the timestamp is visible, the confirmation is clear. This is not surveillance — it is accountability that protects him ("I submitted the reading at 09:15") as much as it informs his manager.

### Cross-cutting App Narrative Themes

#### Offline resilience as character trait
The app works in Luanda, where connectivity drops without warning. Offline is not an error state — it is a design scenario with the same importance as "happy path."

- **Reads:** served from local cache with clear staleness indicators. The interface never blanks. Ghost treatment (desaturation + timestamp) shows what is fresh and what is old.
- **Writes:** queued locally with explicit state progression visible to the user: `Saved offline → Pending sync → Synced` (or `Failed` with a retry option).
- **Sync triggers:** app foreground, connectivity restored, pull-to-refresh. Priority: readings and orders before preferences.
- **Never silently lose data.** If something fails to sync, the user must know. If something synced, the user must know. The state is always visible.

#### Trust through transparency
Every data point in Jila carries metadata about its own reliability:
- **Source:** sensor reading vs. manual input
- **Freshness:** "Last updated: HH:MM"
- **Confidence:** HIGH / MEDIUM / LOW
- **Data gaps:** explicitly shown, never hidden

The UI never hides uncertainty to look slick. "We are not sure" is a valid and valuable answer.

#### Ruthless simplicity
This app may be used by someone who has never used a smartphone app before.

- **One primary action per screen.** The biggest, most prominent element on every screen is the single thing the user should do next. Secondary actions exist but are visually de-emphasized.
- **Single-column layouts.** No multi-column grids, no complex dashboards, no two-dimensional scanning requirements.
- **Step-by-step wizards** for anything complex (setup, ordering, calibration). One question at a time, "Next" progression, visible progress indicator.
- **Large cards and buttons** over dense menus. Tap targets of at least 48dp.
- **Informative empty states.** No blank screens. Every empty state has an illustration, a short explanation, and one primary CTA telling the user what to do next.

#### Outdoor-first
This app is used on rooftops in direct sunlight, in truck cabs, in dusty warehouse compounds. Not in air-conditioned offices.

- **WCAG AAA (7:1+) contrast** for body text. No "cool grey on white."
- **Solar Mode:** a high-contrast light theme that can activate automatically (ambient light sensor with hysteresis) or be toggled manually. True black text on white surfaces.
- **OLED dark mode:** true black background (`#000000`) to save battery on the devices most of Jila's users actually own.
- **Touch targets:** minimum 48dp. Controls should feel pressable — substantial, not hairline.

#### Tangible feedback
In a low-trust environment, confirmation must be physical-feeling:

- **Primary CTA press:** light haptic "click" + immediate pressed state
- **Successful commit** (order created, reading saved): stronger haptic "thud" + clear success state
- **Failure:** distinct haptic pattern + diagnostic card (line-art illustration + short copy + action), never a raw error code
- **Optional sound effects** for high-stakes confirmations (e.g., order accepted) — subtle, mechanical, never forced, always respecting OS mute/silent settings

---

## Part 5 — The Web Portal

### Purpose

The web portal is the **command center for organizations**. If the mobile app is where you experience your own water, the portal is where you oversee everyone's.

### The narrative shift

The emotional register changes fundamentally from mobile to portal:

| Mobile app | Web portal |
|---|---|
| "My water" | "Our water infrastructure" |
| Personal survival | Organizational oversight |
| One reservoir at a time | Many sites at a glance |
| Acting | Managing |
| Used outdoors, one-handed | Used at a desk, with a keyboard |

The portal user is not anxious about running out. They are responsible for making sure *nobody* runs out. Their fear is not empty tanks — it is **invisible risk**: the site that silently went dry while everyone was looking elsewhere.

### Key portal experiences

#### 1. Org bootstrap — "Set up your organization"
A first-time organization user creates their org, adds a first site and reservoir, and invites a team member. The entire flow should take less than 10 minutes.

The tone is professional but not bureaucratic. Guide the user through setup with clear steps, helpful defaults, and immediate value — show them their first reservoir status as soon as possible so they understand what they are building toward.

#### 2. Multi-site risk overview — "Spot trouble in 15 seconds"
The overview dashboard is the portal's equivalent of Maria's tank screen — the first thing the user sees and the surface they return to most.

It must answer one question instantly: **"Which of my sites are at risk right now?"**

Design this as a scannable list or card grid of sites, each showing:
- Site name and location
- Number of reservoirs and their aggregate risk state
- Freshest reading timestamp (staleness matters — a site with no recent data is itself a risk)
- Alert count and severity

Color + icon + text encoding for severity (never color alone). Freshness everywhere. The overview should feel like a control room instrument panel — dense with information but organized by priority.

#### 3. Field update flow — "Submit a reading in under 60 seconds"
A field operator opens the portal on a tablet, finds the reservoir they are standing in front of, and submits a manual reading. This flow must be fast, forgiving (offline tolerance), and attributable (their identity is attached to the reading).

Optimize this path ruthlessly. Three taps maximum from the overview to the reading submission form.

#### 4. Device status — "Is the sensor working?"
For device-monitored sites, the portal shows pairing status, battery level, signal strength, and connectivity state — using the same visual language as the mobile app (bar gauges, Silka Mono data typography, ghost treatment for stale data).

No jargon. "Sensor online, battery 73%" — not "MQTT connection status: CONNECTED, ADC voltage: 3.7V."

#### 5. Alerts review — "What needs my attention?"
The alerts feed is actionable and low-noise. Each alert shows:
- What happened (human-readable, localized)
- Where (site / reservoir / device)
- When
- Severity (CRITICAL / WARNING / INFO with icon + color + label)
- One-tap action (navigate to source, mark read)

Filters by site, reservoir, device, severity, and status. Active-only by default — do not drown the user in resolved history.

#### 6. Evidence export — "Prove it happened"
CSV, PDF, and HTML exports of reservoir/site analytics and readings history — the data that organizations use to contest utility bills, justify budgets, and present in board meetings. This is also Jila's bridge to Phase B, where exports will expand to include intervention summaries, evidence packs, and funder-ready reporting.

The export interface should feel authoritative: clear date-range selection, data-quality disclaimers (gaps, confidence), and professional formatting suitable for formal reporting.

### Portal design directives

| Directive | Rationale |
|---|---|
| Left-nav information architecture | Standard enterprise pattern: Overview → Sites → Reservoirs → Devices → Alerts → Users & Access → Settings |
| Same design language as mobile | IBM Plex Sans + Silka Mono, blue-teal trust palette, Blueprints of Life illustrations — adapted for desktop density |
| Firebase realtime mirroring | Dual-load: HTTP API for initial data, Firestore listeners for live updates. The portal should feel alive — readings update without page refresh |
| Industrial clarity | Tables with visible structure, cards with clear edges. Data-dense but never cluttered. Generous whitespace used for hierarchy, not decoration |
| Mapbox maps with shared style tiles | Same light + dark map variants as mobile. Consistent marker encoding across surfaces |
| Keyboard-navigable | Portal users work with keyboards. Every interactive element must have a visible focus state |

---

## Part 6 — Connecting the Three Surfaces

### One brand, three contexts

The website **sells**. The app **serves**. The portal **governs**. They have different purposes, different users, and different emotional registers — but they must be unmistakably the same product.

A visitor who sees the jila.ai website, then downloads the mobile app, then later logs into the web portal should feel a continuous thread of identity. Not identical interfaces — each surface is optimized for its context — but the same **voice**, the same **values**, and the same **visual DNA**.

### Shared DNA

These elements must be consistent across all three surfaces:

**Typography**
- **IBM Plex Sans** for all narrative/UI text. Weight discipline: `400` body, `500` labels/buttons, `600` headings. No `300` or `700+`.
- **Silka Mono** for data: metrics, timestamps, readings, prices. Credibility accent only — never for paragraphs.
- Tabular numbers for aligned numerics everywhere. Locale-aware formatting with thin-space unit separators (`12.4 L`, `85 %`, `150 000 Kz`).

**Color palette**
- **Blue-teal family** = information, trust, primary navigation (calming, water-associated)
- **Green** = success, confirmation, positive states
- **Warm orange / terracotta** = attention, progress, "in motion"
- **Red** = alerts and failures only (never "attention" or "progress")
- Maximum 3–4 semantic colors. No purple, pink, or decorative bright hues.

**Illustration language — "Blueprints of Life"**
- Technical line art: procedures shown as Ikea-manual-style step sequences (white lines on midnight navy)
- Cutaway / x-ray vision for education: tanks shown in cross-section to build understanding
- Contextual backgrounds: subtle, semi-abstract line art suggesting local context (rooftops, trucks) — never competing with primary content
- Vector-first: lightweight for bandwidth, scalable for any resolution

**Trust posture**
- Freshness timestamps on every data point
- Confidence indicators where estimates are shown
- Honest uncertainty ("~1–2 days" when confidence is low)
- No dark patterns, no fake urgency, no hidden costs
- Data gaps shown explicitly, never hidden

### Progressive trust-building

The three surfaces represent a trust progression:

```
Website              →  Mobile App              →  Web Portal
"I believe this      →  "It actually works      →  "My organization
 could help."            for me every day."          runs on this."
```

Each transition deepens the relationship:

- **Website → App:** The website creates understanding and interest. The app download is a vote of confidence. The first value moment (adding a reservoir, seeing "days remaining") must arrive within four minutes to validate that trust.

- **App → Portal:** As usage matures — more reservoirs, more sites, an organization — the portal becomes the natural next surface. It should feel like the same product at a higher altitude: the same data, the same visual language, but organized for oversight rather than personal use.

### Locale consistency

Portuguese (pt-AO) is the primary language across all surfaces. English is secondary. This is not negotiable.

**Controlled vocabulary** — these terms must be identical across website, app, and portal:

The canonical controlled vocabulary lives in `../mobile_app/09_localization_and_accessibility.md`.

| Portuguese (canonical) | English | Concept |
|---|---|---|
| Reservatório | Reservoir | Water storage container |
| Nível da água | Water level | Current fill percentage |
| Dias restantes | Days remaining | Estimated time-to-empty |
| Encomenda | Order | Water purchase/delivery |
| Vendedor | Seller | Water seller/tanker |
| Ponto de abastecimento | Supply point | Community water source |

The following terms are proposed additions pending canonicalization in the localization spec:

| Portuguese (proposed) | English | Concept |
|---|---|---|
| Última atualização | Last updated | Freshness timestamp |
| Confiança | Confidence | Data reliability indicator |

Never mix synonyms. "Encomenda" is always "Encomenda" — not "Pedido" on one screen and "Encomenda" on another. This consistency is critical for users with limited literacy who learn the app by visual and verbal pattern recognition.

### Design coherence checklist

Before shipping any surface, verify:

- [ ] Typography uses IBM Plex Sans + Silka Mono with correct weight discipline
- [ ] Color palette stays within the 3–4 semantic colors (blue-teal, green, terracotta, red)
- [ ] Every data point shows freshness (timestamp) and source (sensor/manual)
- [ ] No screen uses color as the only signal for status/severity
- [ ] Controlled vocabulary terms are identical across surfaces and match the canonical table
- [ ] Empty states have illustrations + one CTA (no blank screens)
- [ ] Error states use diagnostic cards, not raw error codes
- [ ] Portuguese (pt-AO) is the default language in all user-facing content
- [ ] Body text meets WCAG AAA (7:1) contrast ratio
- [ ] Touch targets (mobile) are at least 48dp
- [ ] Illustrations follow the "Blueprints of Life" visual grammar (line art, not photorealism)
- [ ] Copy avoids guaranteed outcomes ("avoid surprises" not "never run out")

---

## Appendix — Tone of Voice Examples

### Do / Don't table

| Situation | Do | Don't |
|---|---|---|
| Tank is running low | "Nível baixo. Considere encomendar água." (Low level. Consider ordering water.) | "URGENTE! A água vai acabar!" (URGENT! Water will run out!) |
| Data is old | "Última atualização há 3 horas." (Last updated 3 hours ago.) | Show the data without a timestamp |
| Estimate has low confidence | "~1–2 dias restantes (estimativa com poucos dados)" (~1–2 days remaining, estimate with limited data) | "1.5 days remaining" (false precision) |
| Sensor is offline | "Sensor offline. A mostrar últimos dados conhecidos." (Sensor offline. Showing last known data.) | "Error: MQTT_TIMEOUT" |
| Order confirmed | "Encomenda confirmada. O vendedor foi notificado." (Order confirmed. The seller has been notified.) | "Success!" (vague, no next step) |
| Feature requires account | "Inicie sessão para encomendar água." (Log in to order water.) | Block the entire screen with a login wall before showing any content |
| Price is TBD | "Preço a confirmar. Contacte-nos." (Price to be confirmed. Contact us.) | Leave the price field blank without explanation |

### Voice characteristics

- **Clear, not clever.** Prefer plain words over creative copy. "See your water level" over "Dive into your data."
- **Calm, not clinical.** Warm enough to feel human, precise enough to feel reliable. Not robotic, not chatty.
- **Respectful, not condescending.** Explain without over-explaining. Never assume ignorance, but also never assume expertise.
- **Active, not passive.** "We show you when data is old" over "Data staleness indicators are displayed."
- **Short.** Sentences under 15 words when possible. One idea per sentence. No compound constructions.
 