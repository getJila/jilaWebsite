---
title: Jila Mobile App — Asset Inventory & Procurement List (v1)
status: Draft (actionable for procurement)
last_updated: 2025-12-25
---

## Purpose
List the **design + media assets** that must be created/procured to ship the Jila React Native mobile app (Android + iOS) and to support the DECIDED UX patterns (illustration-first, diagnostic gallery, vehicle identification, map marker semantics).

This is written to be used as a **handoff checklist** for design/brand procurement and to unblock implementation.

## Scope & repository note (do not drift)
This document describes assets for the **mobile app repository** (often referred to as `jilaApp`). Some path examples below are
therefore **mobile-repo paths**, not files that exist in this backend repo.

Canonical UX decisions referenced by this inventory live in this repo under `docs/design/*` and `docs/pm/mobile_app/*`.

## Sources (what this is based on)
- App codebase (mobile repo): `<mobile-app-repo>/src/*` (React Native CLI) + platform projects (`<mobile-app-repo>/android`, `<mobile-app-repo>/ios`)
- Canonical screen set (this repo): `docs/pm/mobile_app/11_screen_inventory.md`
- DECIDED illustration + iconography rules (this repo): `docs/design/jila_design_decision_register.md` (UX-D-031/032/033/034/035/039/041/044/045/046)
- Design guide (this repo): `docs/ux/jila_design_guide.md`
- Store distribution decision (this repo): `docs/decision_registers/mobile_app_decision_register.md` (MA-011)

## Constraints to keep in mind (affects what we procure)
- **Vector-first** (UX-D-041): prefer SVG masters for icons/illustrations; export PNGs for runtime if needed.
- **Outdoor readability**: designs must hold up under glare; assume AAA posture for body text and critical UI (see `docs/pm/mobile_app/09_localization_and_accessibility.md`).
- **No photorealism for core flows** (UX-D-032/044): avoid heavy photos/3D renders; use “Blueprints of Life” technical line art.
- **React Native integration note**: the app currently does **not** include `react-native-svg`. If we want SVG rendered in-app, we’ll need to add it; until then, procure **SVG masters + PNG exports**.
- **App icons must not include transparency** (Apple App Store requirement). Ensure final icon exports have **no alpha channel**.

---

## What already exists in the mobile app repo (do not re-procure)
- Brand seed assets:
  - `<mobile-app-repo>/assets/icons/app_icon_1024.png` (baseline mark + wordmark)
  - `<mobile-app-repo>/assets/icons/jila_logo.svg` (note: contains a text element; consider converting text to paths for portability)
- Fonts (already bundled; update to canonical weights if needed):
  - `<mobile-app-repo>/assets/fonts/IBMPlexSans-400.ttf`
  - `<mobile-app-repo>/assets/fonts/IBMPlexSans-500.ttf`
  - `<mobile-app-repo>/assets/fonts/IBMPlexSans-600.ttf`
  - `<mobile-app-repo>/assets/fonts/SilkaMono-400.otf`
  - `<mobile-app-repo>/assets/fonts/SilkaMono-500.otf`
- Platform app icons already present (may need regeneration to match final brand lockup + no-alpha rule):
  - Android launcher icons under `<mobile-app-repo>/android/app/src/main/res/mipmap-*`
  - iOS app icons under `<mobile-app-repo>/ios/JilaApp/Images.xcassets/AppIcon.appiconset`

---

## Asset procurement list (v1)

### 1) Platform + store listing assets (P0 to ship)
| Asset | Priority | Where used | Deliverables / spec |
|---|---:|---|---|
| App icon (master) | P0 | iOS/Android app icon, store listing | 1024×1024 master (no alpha), plus vector master if available; regenerate all required platform sizes from this |
| iOS AppIcon set | P0 | `Images.xcassets/AppIcon.appiconset` | PNG exports for all sizes in `Contents.json` (20/29/40/60 @2x/@3x + 1024) **with no alpha** |
| Android launcher icons | P0 | `@mipmap/ic_launcher*` | PNG exports for mdpi/hdpi/xhdpi/xxhdpi/xxxhdpi + round variant; keep crisp at small sizes |
| Android adaptive icon (foreground/background) | P1 (recommended) | Modern Android launchers | Foreground + background layers (vector preferred) + generated mipmaps; improves icon fidelity across devices |
| Android notification icon | P0 (if FCM push ships) | Push notifications status bar | 24×24dp white-only silhouette (PNG in drawable-*); add as `default_notification_icon` meta-data in AndroidManifest when implemented |
| Splash / launch branding | P0 | App launch (iOS LaunchScreen + Android launch theme) | Simple branded launch (logo/mark + background). Keep lightweight (no large raster). Provide: (1) mark-only lockup, (2) wordmark lockup, (3) background color tokens |
| App Store screenshots | P0 | Apple App Store | Curated screenshots for supported device sizes (at minimum iPhone 6.7" and 6.5"); include localized variants (pt-AO, en) or design for minimal text overlays |
| Play Store screenshots | P0 | Google Play listing | 6–8 screenshots (phone), localized (pt-AO, en) or minimal text overlays |
| Play Store feature graphic | P0 | Google Play listing | 1024×500 feature graphic, minimal copy, high contrast |
| Store preview video | P2 | Store listing | Optional short demo; keep bandwidth low; avoid relying on audio |

### 2) Core in-app illustration library (“Blueprints of Life”) (P0)
These assets are required by DECIDED UX rules for low-literacy comprehension and offline trust (UX-D-032/039/041).

**Procurement output for each illustration**
- Master: SVG (preferred) with text converted to outlines, consistent stroke weight.
- Exports: PNG @1x/@2x/@3x (if not using SVG runtime yet).
- Variants: dark-surface (midnight navy) and light-surface (Solar Mode) where applicable.
- Copy: keep captions minimal; do not embed long text in the art (strings must be localizable in code).

| Asset set | Priority | Where used (screens/features) | Count (suggested) |
|---|---:|---|---:|
| First-run tutorial panels (MA-006) | P0 | `FirstRunTutorial` | 2–3 panels |
| “How Jila works” cutaway (tank + sensor) | P0 | `ReservoirHowItWorks` (and/or `ReservoirDetail` explainer) | 1–3 illustrations (single + optional sequence) |
| Diagnostic gallery (UX-D-039) | P0 | Monitoring failures + `DiagnosticsTips` | 5 core diagnostics: network down, sensor unreachable, low battery, stale reading, permission required |
| Empty state illustrations (UX-D-032) | P0 | Home/Orders/Alerts/Map/Marketplace empty states | 5–7 (at minimum: no reservoirs, no orders, no alerts, map no results, marketplace no sellers) |
| Offline/sync state pictograms | P1 | “Saved offline / pending sync / failed” surfaces | 3 small pictograms (optional if using MCI icons only) |
| Coach-mark micro-help illustrations | P1 | Map “use current location” (MA-030), pull-to-refresh (UX-D-037) | 2–3 small callouts |

### 3) Delivery vehicle illustration set (UX-D-034) (P0 for marketplace clarity)
Accurate technical line art used in replenishment and ordering flows (reliability + trust).

| Asset | Priority | Where used | Deliverables / spec |
|---|---:|---|---|
| Vehicle silhouettes (small/med/large) | P0 | Replenishment Card, order confirm/detail, receipts | 3–5 vehicle types relevant to Luanda reality (e.g., “tuk-tuk tanker”, small pickup tank, medium truck, large tanker). SVG master + PNG exports |
| Vehicle label chips | P1 | Same as above | Small icon+label variants that remain legible outdoors |

### 4) Map markers + legend icons (UX-D-031) (P0)
Map is a primary entry path (“Find water nearby”), and marker semantics must be legible + lightweight.

| Asset | Priority | Where used | Deliverables / spec |
|---|---:|---|---|
| Marker base shapes (SupplyPoint vs Seller) | P0 | `SupplyPointsMap`, `SupplyPointDetail` | 2 silhouettes (high contrast, thick strokes) |
| Supply point kind icons | P0 | Map markers + detail sheet | 6 icons matching `SupplyPointKind`: STANDPIPE, RIVER, BOREHOLE, KIOSK, DEPOT, OTHER |
| Availability status badges | P0 | Markers + legend | 5 statuses (AVAILABLE/LOW/NONE/CLOSED/UNKNOWN) as small badge glyphs or overlays (color + icon redundancy) |
| Filter chip icons | P1 | Map bottom sheet filters | 4–6 small icons for kinds/status chips |

### 5) Trust & identity assets (UX-D-035) (P1, depends on backend fields)
| Asset | Priority | Where used | Deliverables / spec |
|---|---:|---|---|
| Driver ID badge frame/background | P1 | `OrderDetail` (delivery context) | Card frame/background motif + placeholder avatar silhouette (vector) |
| Verified/Trust badge (optional) | P2 | Marketplace listings, seller profile | Simple checkmark badge variants; avoid implying verification unless backed by policy/data |

### 6) Sound assets for “tangible feedback” (UX-D-043) (P2)
Only if you decide to ship optional mechanical sound reinforcement (must respect OS mute/silent).

| Asset | Priority | Where used | Deliverables / spec |
|---|---:|---|---|
| UI confirm click | P2 | Primary CTA press | `wav` (short, subtle), plus `m4a` if needed |
| Success thud | P2 | Order created / accept / saved | `wav` (short, subtle) |
| Error tick | P2 | Failure states | `wav` (short, subtle) |

---

## Recommended file organization (so assets don’t drift)
If/when we start adding these assets to the repo, keep them grouped and named for reuse:
- `<mobile-app-repo>/assets/brand/` (logos, lockups)
- `<mobile-app-repo>/assets/illustrations/blueprints/` (tutorials, how-it-works, diagnostics, empty states)
- `<mobile-app-repo>/assets/illustrations/vehicles/` (UX-D-034)
- `<mobile-app-repo>/assets/map/markers/` (UX-D-031)
- `<mobile-app-repo>/assets/sounds/` (optional)

Naming suggestion:
- Use stable IDs aligned to screens/patterns, e.g. `diag_network_down`, `empty_orders`, `tutorial_panel_1`, `vehicle_tuktuk_tanker`.

---

## Acceptance checklist (use for vendor/design QA)
- Exports are crisp at small sizes and in sunlight (high contrast, no hairlines).
- SVG masters have text converted to outlines (no font dependency).
- App icon exports contain **no alpha channel**.
- Illustrations follow “Blueprints of Life” language (white-line technical drawings, consistent stroke weights).
- Assets avoid culturally confusing artifacts; vehicle/container imagery matches Luanda reality.
- Any badge implying “verified” is only used if backed by product policy + backend fields.
