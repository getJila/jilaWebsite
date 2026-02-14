# AI Localized Directions (Landmark-Based, Voice-First) — Backlog Spec (P3)

> **Status:** Backlog / exploration spec (explicitly not v1 scope)<br>
> **Last updated:** 2025-12-26<br>
> **Related v1 journey:** `./02_user_journey_maps.md` (Journey 5 — “Directions is one tap”)<br>
> **Related scope doc:** `./03_feature_requirements_document.md` (Community supply points → P3)<br>
> **Related accessibility guidance:** `./10_inclusive_design_guidelines.md` (Voice and Audio Assistance)

## Purpose
Backlog a new “directions” capability that helps users reach a location when GPS-style navigation is not effective or not culturally aligned.

This feature generates **landmark-based, local-style** directions and optionally provides **audio playback** for low-literacy / outdoor contexts.

## Problem statement
In many markets, people commonly give directions using **known landmarks and points of interest** (“turn at the big church, pass the market, then…”). GPS turn-by-turn can fail due to:
- low familiarity with map UIs,
- unreliable connectivity,
- ambiguous addressing,
- language/literacy barriers.

## Target surfaces (where it appears)
- **SupplyPoint detail**: “Directions” (v1) and “Local directions” (future).
- Future candidates: seller locations, pickup points, reservoir sites (org use).

## v1 baseline (must remain stable)
For v1, “Directions” means: **one tap opens the native maps app** (Apple Maps / Google Maps) with the destination prefilled.

This backlog feature must not change v1 behavior or add new v1 requirements implicitly.

## Proposed feature (future) — “Local directions”
Provide a secondary option on location detail screens:
- **Local directions (Listen)**: plays a short audio clip of landmark-based instructions.
- **Local directions (Read)**: shows the same instructions as short, plain-language steps.

## Inputs and dependencies (future)
To generate non-hallucinatory, local directions we likely need:
- **Target location**: lat/lng (existing for SupplyPoints).
- **Locality metadata**: city/region + preferred language/locale (pt-AO first; English second).
- **Landmarks dataset**: a vetted set of POIs/landmarks per locality (not user-generated at runtime).
- **Optional**: “starting anchors” (e.g., from city center / main market / bus terminal) that locals commonly reference.

## Output shape (conceptual; not an API contract yet)
For each location + locale:
- `directions_text`: short steps (3–8), plain language, landmark references.
- `audio_asset`: pre-generated audio (or a deterministic TTS recipe) with caching/offline considerations.
- `sources`: which landmarks/anchors were used (for review/debug).
- `version`: so regenerated scripts can be tracked over time.

## Quality and safety constraints (non-negotiables)
- **No invented landmarks**: instructions must only reference landmarks from a known/approved set.
- **Clear uncertainty**: if landmark coverage is insufficient, degrade gracefully to “Open Maps” only (do not fabricate).
- **Short and skimmable**: each step is one sentence; avoid long paragraphs.
- **Privacy**: do not require sending the user’s real-time location to third parties to produce the script (prefer pre-generation per location).
- **Localization**: Portuguese-first; any additional languages require explicit resourcing.

## Suggested technical approach (future)
- **Generate offline / ahead of time** when a SupplyPoint is created/updated or curated (server-side job).
- Use a retrieval-based prompt that:
  - takes a vetted list of nearby landmarks and anchors,
  - produces 3–8 steps,
  - outputs a structured format that is validated before storage.
- Produce audio as:
  - **Option A**: backend-generated TTS → store audio URL (CDN/object store), or
  - **Option B**: client-side TTS with cached text + voice selection (requires mobile platform decisions).

## UX notes (future)
- Keep the default action as **Open Maps** (low friction).
- “Local directions” should be **secondary** and clearly labeled as “local-style / landmark-based”.
- Provide a one-tap **Copy** action for the text (sharing with a driver is common).

## Acceptance criteria (future milestone)
- On SupplyPoint detail, user can:
  - tap **Open Maps** (existing v1 behavior), and
  - tap **Local directions** to see steps and play audio when available.
- If local directions are missing/unavailable:
  - the UI shows a simple message (“Local directions not available yet”) and still offers **Open Maps**.
- Local directions are:
  - short, in plain language,
  - only reference known landmarks,
  - locale-appropriate (pt-AO first).

## Non-goals (explicit)
- Turn-by-turn GPS route optimization.
- Real-time navigation tracking.
- Crowdsourced, unmoderated landmark references.
- Using device-local timestamps or user location history for generation.

## Open questions (to decide later)
- Do we require **human review** before publishing AI-generated scripts for a locality?
- How do we choose anchors (“from where”) so instructions remain broadly useful?
- What is the first target locality, and how do we source/maintain the landmark set?
- How do we measure success (completion rate, reduced confusion, user trust) without heavy analytics?


