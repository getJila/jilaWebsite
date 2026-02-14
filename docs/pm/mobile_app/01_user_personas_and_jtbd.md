# Jila Mobile App — Personas & JTBD (Core)

> **Status:** Condensed / low-drift reference
> 
> **Last updated:** 2025-12-20

## Purpose
Capture the **minimum persona/JTBD set** needed to keep product scope coherent and reduce drift. This doc should not contain API details or screen scripts.

## Context (Luanda)
- **Intermittent water** and **high cost of running out** drive anxiety and urgent decisions.
- **Connectivity is unreliable**; the app must remain useful offline.
- **Mixed digital literacy**; UX must be simple, forgiving, and trust-building.
- **Portuguese-first**.

## Primary personas (v1)

### 1) Maria — Household water manager
- **Primary job**: *Know when to refill so I don’t run out and don’t overspend.*
- **Key risks**: distrust of apps, uncertain estimates, data costs.
- **What “success” looks like**: within minutes, Maria can add a reservoir and see an understandable “days remaining” estimate with last-updated and confidence.

### 2) Carlos — Water seller (tanker)
- **Primary job**: *Get real nearby orders so I don’t waste time/fuel.*
- **Key risks**: missed orders, pricing complexity, unclear payoff.
- **What “success” looks like**: seller can set a simple price + availability and receive/respond to orders reliably.

### 3) Joana — Community water seeker
- **Primary job**: *Find water near me that’s actually available right now.*
- **Key risks**: outdated info, wasted trips, login friction.
- **What “success” looks like**: Marketplace discovery works without account (Community + Sellers); contributing updates and ordering require login (spam/control + permissions).

### 4) António — Organization field operator
- **Primary job**: *See and report site water status so I don’t get blamed for problems.*
- **Key risks**: extra work, unclear responsibility boundaries.
- **What “success” looks like**: invited user lands in the correct org-scoped view and can perform quick, auditable updates.

## Cross-persona product implications (v1)
- **Manual-first**: the core experience must work without a device.
- **Trust UI is non-negotiable**: show last updated, source, and “confidence/uncertainty” clearly.
- **Offline and “saved vs synced” clarity**: never lose user-entered data.
- **Role entry**: allow a clear path for each persona; community discovery should not be gated by account creation.

## Non-goals (keep out of PM docs)
- Per-endpoint API payload examples (canonical source is the backend API contract).
- Pixel-perfect onboarding scripts / wireframes in prose.

## Open questions
- Are Joana/community flows part of v1 launch in all markets, or a phased feature?
- How much org functionality is v1 mobile vs web-only?

## References
- Core flows: `./02_user_journey_maps.md`
- Feature scope/priorities: `./03_feature_requirements_document.md`
- UX guidelines: `../../ux/jila_application_ux_guidelines.md`
