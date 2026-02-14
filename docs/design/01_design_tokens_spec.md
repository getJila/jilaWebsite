---
title: Jila UI — Web Design Tokens Mapping (v1) (MUI 7)
status: DECIDED
last_updated: 2026-01-14
decision_ref: WP-090, WP-014
references:
  - ./jila_theme_and_brand_tokens_v1.md
  - ./02_component_patterns_spec.md
  - ../decision_registers/web_portal_decision_register.md
---

## Purpose

This document defines the **web implementation mapping** of the canonical Jila theme tokens into a **MUI 7 React theme**
and shared component styles. It is a contract.

> **Source of Truth**: This specification is the authoritative source for the MUI theme configuration
> in the Web Portal. The theme implementation at `app/theme/` MUST derive from these token mappings.
> See decision WP-014 for theme integration details.

This document does not prescribe styling mechanisms. The requirement is: **the MUI 7 theme + component variants MUST
reflect the canonical tokens**.

Canonical (cross-platform) tokens:
- `./jila_theme_and_brand_tokens_v1.md`

Component patterns (MUI-first):
- `./02_component_patterns_spec.md`

Rule: this document MAY define **web-only computed values** (hover alphas, focus rings, glass blur/alpha). It MUST NOT
redefine base brand colors or semantic meanings.

---

## 1) Palette mapping (MUI 7: `theme.palette`)

Base colors and semantics come from `./jila_theme_and_brand_tokens_v1.md`.

### 1.1 Required palette slots

- `palette.primary.main` = canonical `primary` (Aqua Teal) `#4ECDC4`
- `palette.secondary.main` = canonical `secondary` (Deep Ocean Blue) `#1950B8`
- `palette.error.main` = canonical `error` `#EF4444`
- `palette.critical.main` = canonical `critical` `#DC2626` (domain risk state, see WP-015)
- `palette.success.main` = canonical `success` `#22C55E`
- `palette.warning.main` = canonical `warning` `#D87C4A`
- `palette.info.main` = canonical `info` `#248CFF`

Surfaces:
- `palette.background.default` = canonical dark `background` `#0D1B2A`
- `palette.background.paper` = canonical `surface` `#111C2C`

Text:
- `palette.text.primary` = canonical `text_primary_dark` `#FFFFFF`
- `palette.text.secondary` = canonical `text_secondary_dark` `#D1D5DB`

### 1.2 `onPrimary` guidance (critical for contrast)

Because `primary` is a **light teal**, `palette.primary.contrastText` should be a **dark** text color for AAA posture
in bright conditions (typically black `#000000` or a dark navy aligned to the surface system).

Do not default to white text on teal without verifying contrast.

### 1.3 Web-only computed palette helpers (allowed)

These are **computed** from canonical base colors and may be implemented as:
- additional palette entries (if you choose), or
- utility functions in the UI package.

Computed values (v1):
- `primary.hover` = `rgba(78, 205, 196, 0.90)` (or a slightly darker teal)
- `primary.tint10` = `rgba(78, 205, 196, 0.10..0.14)` (selected state backgrounds)
- `focusRing.primary` = `rgba(78, 205, 196, 0.18..0.22)`

### 1.4 Light Mode (Solar) palette slots

Solar Mode is the high-contrast light theme for outdoor/bright conditions (see WP-014).

Surfaces:
- `palette.background.default` = canonical `background_solar` `#FFFFFF`
- `palette.background.paper` = canonical `surface_solar` `#EAF3FF`

Text:
- `palette.text.primary` = canonical `text_primary_light` `#000000`
- `palette.text.secondary` = canonical `text_secondary_light` `#1F2937`

Contrast text:
- `palette.primary.contrastText` = canonical `onPrimary` `#000000` (black text on teal CTAs for AAA contrast)

Notes:
- Solar Mode surfaces are flat (no gradients) per UX-P-006
- All text must achieve AAA (7:1) contrast against Solar surfaces
- Primary buttons retain teal background with black text

---

## 2) Typography mapping (MUI 7: `theme.typography`)

Canonical intent (do not drift): "Data vs. Narrative" voice from `./jila_theme_and_brand_tokens_v1.md`.

Web-specific note:
- **Strict no-fallback**: no fallback stacks; load the canonical fonts before render.

### 2.1 Font families

| Token | MUI 7 mapping | Value |
|-------|---------------|-------|
| Narrative font | `typography.fontFamily` | `'IBM Plex Sans'` |
| Data font | `typography.fontFamilyMono` | `'Silka Mono'` |

### 2.2 Heading variants

| Variant | Font size | Weight | Line height | Use case |
|---------|-----------|--------|-------------|----------|
| `typography.h1` | 48px / 3rem | 600 | 1.2 | Page titles |
| `typography.h2` | 36px / 2.25rem | 600 | 1.2 | Section headers |
| `typography.h3` | 30px / 1.875rem | 600 | 1.22 | Card titles |
| `typography.h4` | 24px / 1.5rem | 600 | 1.22 | Subsection headers |
| `typography.h5` | 20px / 1.25rem | 600 | 1.25 | Widget titles |
| `typography.h6` | 18px / 1.125rem | 600 | 1.25 | Minor headers |

### 2.3 Body variants

| Variant | Font size | Weight | Line height | Use case |
|---------|-----------|--------|-------------|----------|
| `typography.body1` | 16px / 1rem | 400 | 1.5 | Primary body text |
| `typography.body2` | 14px / 0.875rem | 400 | 1.45 | Secondary body text |
| `typography.subtitle1` | 16px / 1rem | 500 | 1.4 | Card subtitles |
| `typography.subtitle2` | 14px / 0.875rem | 500 | 1.35 | Minor subtitles |
| `typography.caption` | 12px / 0.75rem | 400 | 1.35 | Labels, timestamps |
| `typography.overline` | 12px / 0.75rem | 500 | 1.3 | Section labels (uppercase) |

Line-height rules (canonical):
- Body (14–16 px): `1.45–1.5`
- Long-form reading (16–18 px): `1.55–1.6` (use a prose class or variant for long-form)
- Labels / UI controls (12–14 px): `1.3–1.4`
- Headings (any size): `1.15–1.25` (never exceed `1.25`)

### 2.4 Custom variants (MUI 7 module augmentation)

| Custom variant | Font | Font size | Weight | Use case |
|----------------|------|-----------|--------|----------|
| `typography.kpi` | Mono | 32px / 2rem | 500 | KPI/metric displays |
| `typography.reading` | Mono | 24px / 1.5rem | 400 | Sensor readings |

Mono line-height rules:
- Tables / inline values (12–14 px): `1.35–1.4`
- KPIs (16–24 px): `1.2–1.3`
- Logs (12 px): `1.4`
- Apply `fontVariantNumeric: 'tabular-nums'` to mono data variants.

Note: Custom variants require TypeScript module augmentation in MUI 7:

```ts
declare module '@mui/material/styles' {
  interface TypographyVariants {
    kpi: React.CSSProperties;
    reading: React.CSSProperties;
  }
  interface TypographyVariantsOptions {
    kpi?: React.CSSProperties;
    reading?: React.CSSProperties;
  }
}

declare module '@mui/material/Typography' {
  interface TypographyPropsVariantOverrides {
    kpi: true;
    reading: true;
  }
}
```

### 2.5 Web Portal typography usage rules (v1)
These rules apply to the Web Portal and must align with the canonical typography contract:

- **IBM Plex Sans (Narrative/UI)**:
  - Body/descriptions: `400`
  - Table headers: `500`
  - Filters/form labels: `500`
  - Section headers: `600`
  - Navigation (sidebar/topbar): `500`
- **Silka Mono (Data)**:
  - Table numeric values: `400`
  - Highlighted KPIs: `500`
  - System states/codes: `500`
  - Logs/raw readings: `400`

Rules:
- Hierarchy should come from **weight + spacing**, not heavy bolding.
- Avoid bolding numbers unless the number is the point.
- Use **tabular numbers** for aligned data columns and KPI blocks.
- Units use a **thin space** (`12.4 L`, `3 m³`, `85 %`).
- Emphasize numeric values with weight, not color; keep units lighter.

### 2.6 Letter-spacing rules (canonical)
- **Labels / buttons**: `+0.01em`
- **All-caps labels**: `+0.04–0.06em`
- **Headings**: `-0.01em` (optional, only if large sizes feel tight)
- **Mono dense tables**: `+0.02em`
- **Mono small (≤12 px)**: `+0.03em`
- Never use negative tracking on mono.

### 2.7 Numeric formatting rules (canonical)
- Locale-aware formatting; always include thousand separators.
- Tabular numbers for aligned numeric UI.
- Emphasize values via weight, not color; avoid bolding units.

### 2.8 Web implementation notes (Tailwind + font assets)
If the website uses Tailwind, align with the canonical contract and **no fallback stacks**:

```js
// tailwind.config.js
module.exports = {
  theme: {
    extend: {
      fontFamily: {
        sans: ['"IBM Plex Sans"'],
        mono: ['"Silka Mono"'],
      },
      letterSpacing: {
        label: '0.01em',
        caps: '0.05em',
        monoDense: '0.02em',
        monoSmall: '0.03em',
        headingTight: '-0.01em',
      },
      lineHeight: {
        body: '1.5',
        reading: '1.6',
        label: '1.35',
        heading: '1.2',
        mono: '1.4',
        monoKpi: '1.25',
      },
    },
  },
  plugins: [
    ({ addUtilities }) => {
      addUtilities({
        '.nums-tabular': { fontVariantNumeric: 'tabular-nums' },
        '.nums-slashed': { fontVariantNumeric: 'slashed-zero' },
        '.nums-tabular-slashed': { fontVariantNumeric: 'tabular-nums slashed-zero' },
      });
    },
  ],
};
```

Font assets (family names must match):
```css
@font-face {
  font-family: "IBM Plex Sans";
  src: url("/fonts/IBMPlexSans-Regular.woff2") format("woff2");
  font-weight: 400;
  font-style: normal;
  font-display: block;
}
@font-face {
  font-family: "IBM Plex Sans";
  src: url("/fonts/IBMPlexSans-Medium.woff2") format("woff2");
  font-weight: 500;
  font-style: normal;
  font-display: block;
}
@font-face {
  font-family: "IBM Plex Sans";
  src: url("/fonts/IBMPlexSans-SemiBold.woff2") format("woff2");
  font-weight: 600;
  font-style: normal;
  font-display: block;
}
@font-face {
  font-family: "Silka Mono";
  src: url("/fonts/SilkaMono-Regular.woff2") format("woff2");
  font-weight: 400;
  font-style: normal;
  font-display: block;
}
@font-face {
  font-family: "Silka Mono";
  src: url("/fonts/SilkaMono-Medium.woff2") format("woff2");
  font-weight: 500;
  font-style: normal;
  font-display: block;
}
```

Tailwind Typography plugin override (optional, website prose):
```js
const typography = require("@tailwindcss/typography");

module.exports = {
  theme: {
    extend: {
      typography: (theme) => ({
        jila: {
          css: {
            fontFamily: theme("fontFamily.sans").join(","),
            fontWeight: "400",
            lineHeight: theme("lineHeight.reading"),
            p: { marginTop: "0.9em", marginBottom: "0.9em" },
            h1: {
              fontFamily: theme("fontFamily.sans").join(","),
              fontWeight: "600",
              lineHeight: theme("lineHeight.heading"),
              letterSpacing: theme("letterSpacing.headingTight"),
              marginTop: "0",
              marginBottom: "0.6em",
            },
            h2: {
              fontFamily: theme("fontFamily.sans").join(","),
              fontWeight: "600",
              lineHeight: theme("lineHeight.heading"),
              letterSpacing: theme("letterSpacing.headingTight"),
              marginTop: "1.6em",
              marginBottom: "0.6em",
            },
            h3: {
              fontFamily: theme("fontFamily.sans").join(","),
              fontWeight: "500",
              lineHeight: theme("lineHeight.heading"),
              marginTop: "1.4em",
              marginBottom: "0.5em",
            },
            h4: {
              fontFamily: theme("fontFamily.sans").join(","),
              fontWeight: "500",
              lineHeight: theme("lineHeight.heading"),
              marginTop: "1.2em",
              marginBottom: "0.5em",
            },
            strong: { fontWeight: "600" },
            a: { fontWeight: "500", textDecorationThickness: "from-font" },
            code: {
              fontFamily: theme("fontFamily.mono").join(","),
              fontWeight: "400",
              lineHeight: theme("lineHeight.mono"),
              fontVariantNumeric: "tabular-nums",
              letterSpacing: "0",
            },
            pre: {
              fontFamily: theme("fontFamily.mono").join(","),
              fontWeight: "400",
              lineHeight: theme("lineHeight.mono"),
              fontVariantNumeric: "tabular-nums",
              letterSpacing: theme("letterSpacing.monoDense"),
            },
            table: {
              fontFamily: theme("fontFamily.mono").join(","),
              fontVariantNumeric: "tabular-nums",
              lineHeight: theme("lineHeight.mono"),
              letterSpacing: theme("letterSpacing.monoDense"),
            },
            thead: { fontFamily: theme("fontFamily.sans").join(",") },
            "thead th": {
              fontWeight: "500",
              letterSpacing: theme("letterSpacing.label"),
            },
            li: { marginTop: "0.35em", marginBottom: "0.35em" },
            blockquote: {
              fontFamily: theme("fontFamily.sans").join(","),
              fontWeight: "400",
              lineHeight: theme("lineHeight.reading"),
            },
          },
        },
        "jila-invert": {
          css: {
            fontFamily: theme("fontFamily.sans").join(","),
            fontWeight: "400",
            lineHeight: theme("lineHeight.reading"),
            h1: { fontWeight: "600", lineHeight: theme("lineHeight.heading") },
            h2: { fontWeight: "600", lineHeight: theme("lineHeight.heading") },
            h3: { fontWeight: "500", lineHeight: theme("lineHeight.heading") },
            h4: { fontWeight: "500", lineHeight: theme("lineHeight.heading") },
            code: {
              fontFamily: theme("fontFamily.mono").join(","),
              fontVariantNumeric: "tabular-nums",
            },
            pre: {
              fontFamily: theme("fontFamily.mono").join(","),
              fontVariantNumeric: "tabular-nums",
              letterSpacing: theme("letterSpacing.monoDense"),
            },
            table: {
              fontFamily: theme("fontFamily.mono").join(","),
              fontVariantNumeric: "tabular-nums",
              letterSpacing: theme("letterSpacing.monoDense"),
            },
          },
        },
      }),
    },
  },
  plugins: [typography],
};
```

Class recipes (copy/paste):
- IBM Plex Sans
  - Body: `font-sans font-normal leading-body`
  - Label: `font-sans font-medium tracking-label leading-label`
  - Heading: `font-sans font-semibold leading-heading tracking-headingTight`
- Silka Mono
  - Data default: `font-mono font-normal leading-mono nums-tabular`
  - KPI: `font-mono font-medium leading-monoKpi nums-tabular`
  - Dense numeric table: `font-mono font-normal tracking-monoDense leading-mono nums-tabular`
  - Small mono: `font-mono font-normal tracking-monoSmall leading-mono nums-tabular`

Quick sanity checklist:
- Only `IBM Plex Sans` and `Silka Mono` appear in computed styles
- Only weights `400/500/600` (sans) and `400/500` (mono) appear
- Tabular numbers enabled on aligned numeric surfaces
- Mono used only for data surfaces (no paragraphs)


---

## 3) Spacing + shape mapping (MUI 7: `theme.spacing`, `theme.shape`)

Canonical scale: `./jila_theme_and_brand_tokens_v1.md` (Spacing + radius).

### 3.1 Spacing

MUI 7 uses a spacing function where `theme.spacing(n)` returns `n * base` pixels.

| Token | MUI 7 usage | Value |
|-------|-------------|-------|
| xs | `theme.spacing(1)` | 4px |
| sm | `theme.spacing(2)` | 8px |
| md | `theme.spacing(3)` | 12px |
| base | `theme.spacing(4)` | 16px |
| lg | `theme.spacing(6)` | 24px |
| xl | `theme.spacing(8)` | 32px |
| 2xl | `theme.spacing(12)` | 48px |

Configuration:
```ts
spacing: 4 // Base unit in pixels
```

### 3.2 Border radius (shape)

| Token | MUI 7 mapping | Value | Use case |
|-------|---------------|-------|----------|
| sm | `shape.borderRadiusSm` | 8px | Chips, small controls, badges |
| md | `shape.borderRadius` | 12px | Buttons, cards, inputs (default) |
| lg | `shape.borderRadiusLg` | 16px | Dialogs, modals, large panels |
| full | n/a (use `borderRadius: '50%'`) | 50% | Avatars, circular elements |

Configuration:
```ts
shape: {
  borderRadius: 12, // Default (md)
}
```

Note: MUI 7 only provides `shape.borderRadius` by default. Additional radius tokens (`borderRadiusSm`, `borderRadiusLg`)
require theme augmentation:

```ts
declare module '@mui/material/styles' {
  interface Shape {
    borderRadiusSm: number;
    borderRadiusLg: number;
  }
}
```

---

## 4) “Glass” surface effect (web-only, optional)

Important: “Glass” is an **effect**, not a brand token. Use it sparingly and only if it preserves contrast and
readability (UX-P-001/009).

Computed effect parameters (v1):
- panel background alpha: ~0.70
- blur: 12px (panels), 24px (modals)
- subtle border: white at 0.08 alpha

Implementation guidance (MUI 7):
- Implement as shared `Paper`/`Card` variants via `components.MuiPaper.styleOverrides` or the `variants` array.
- Do not require consumers to apply ad-hoc styles.

Example MUI 7 component variant:
```ts
components: {
  MuiPaper: {
    variants: [
      {
        props: { variant: 'glass' },
        style: {
          backgroundColor: 'rgba(17, 28, 44, 0.70)',
          backdropFilter: 'blur(12px)',
          border: '1px solid rgba(255, 255, 255, 0.08)',
        },
      },
    ],
  },
}
```

---

## 5) Focus rings and accessibility

Non-negotiables:
- Visible focus ring on all keyboard-focusable elements.
- Do not rely on color alone for meaning (UX-P-005).
- Text contrast posture is AAA for body text (UX-D-046).

Requirement (v1):
- Focus ring uses a computed `primary` glow (rgba teal) and does not get lost against dark surfaces.

MUI 7 implementation:
```ts
components: {
  MuiButtonBase: {
    styleOverrides: {
      root: {
        '&:focus-visible': {
          outline: 'none',
          boxShadow: '0 0 0 3px rgba(78, 205, 196, 0.20)',
        },
      },
    },
  },
}
```

---

## 6) Minimal reference: MUI 7 theme skeleton (illustrative, not exhaustive)

> **Note**: This skeleton demonstrates the token mappings. The actual theme implementation
> should live in `app/theme/` and include all typography variants, component overrides,
> and module augmentations as specified above.

```ts
import { createTheme } from "@mui/material/styles";

export const theme = createTheme({
  palette: {
    mode: "dark",
    primary: { main: "#4ECDC4", contrastText: "#000000" },
    secondary: { main: "#1950B8", contrastText: "#FFFFFF" },
    error: { main: "#EF4444" },
    success: { main: "#22C55E" },
    warning: { main: "#D87C4A" },
    info: { main: "#248CFF" },
    background: { default: "#0D1B2A", paper: "#111C2C" },
    text: { primary: "#FFFFFF", secondary: "#D1D5DB" },
  },
  typography: {
    fontFamily: "'IBM Plex Sans'",
    fontFamilyMono: "'Silka Mono'",
    h1: { fontSize: '3rem', fontWeight: 600, lineHeight: 1.2 },
    h2: { fontSize: '2.25rem', fontWeight: 600, lineHeight: 1.2 },
    h3: { fontSize: '1.875rem', fontWeight: 600, lineHeight: 1.22 },
    h4: { fontSize: '1.5rem', fontWeight: 600, lineHeight: 1.22 },
    h5: { fontSize: '1.25rem', fontWeight: 600, lineHeight: 1.25 },
    h6: { fontSize: '1.125rem', fontWeight: 600, lineHeight: 1.25 },
    body1: { fontSize: '1rem', fontWeight: 400, lineHeight: 1.5 },
    body2: { fontSize: '0.875rem', fontWeight: 400, lineHeight: 1.45 },
    subtitle1: { fontSize: '1rem', fontWeight: 500, lineHeight: 1.4 },
    subtitle2: { fontSize: '0.875rem', fontWeight: 500, lineHeight: 1.35 },
    caption: { fontSize: '0.75rem', fontWeight: 400, lineHeight: 1.35 },
    overline: { fontSize: '0.75rem', fontWeight: 500, lineHeight: 1.3 },
    kpi: {
      fontFamily: "'Silka Mono'",
      fontSize: '2rem',
      fontWeight: 500,
      lineHeight: 1.25,
      fontVariantNumeric: 'tabular-nums',
    },
    reading: {
      fontFamily: "'Silka Mono'",
      fontSize: '1.5rem',
      fontWeight: 400,
      lineHeight: 1.35,
      fontVariantNumeric: 'tabular-nums',
    },
  },
  shape: { borderRadius: 12 },
  spacing: 4,
});
```

---

## Cross-Platform Theme Mapping

This section documents how Jila design tokens map to platform-specific theme implementations.

### Token → Platform Mapping

| Jila Token | MUI 7 (Web) | React Native Paper (Mobile) |
|------------|-------------|----------------------------|
| `color.primary.main` | `palette.primary.main` | `colors.primary` |
| `color.secondary.main` | `palette.secondary.main` | `colors.secondary` |
| `color.background.default` | `palette.background.default` | `colors.background` |
| `color.surface.main` | `palette.background.paper` | `colors.surface` |
| `color.error.main` | `palette.error.main` | `colors.error` |
| `color.warning.main` | `palette.warning.main` | `colors.warning` (custom) |
| `color.success.main` | `palette.success.main` | `colors.success` (custom) |
| `typography.fontFamily.narrative` | `typography.fontFamily` | `fonts.regular` |
| `typography.fontFamily.data` | Custom `fontFamilyMono` | `fonts.mono` (custom) |
| `spacing.unit` (4px) | `theme.spacing(1)` | `spacing.s` (custom scale) |
| `shape.borderRadius.md` | `shape.borderRadius` | `roundness` |

### Cross-Platform Decisions

| Aspect | Decision | Reference |
|--------|----------|-----------|
| Icon library | Material Community Icons (authoritative) | UX-D-030, WP-020 |
| Date/time | date-fns | WP-060, MA-035 |
| HTTP client | Native fetch | WP-033, MA-036 |
| Data fetching | TanStack Query | WP-030, MA-023 |
| Forms | React Hook Form + Zod | WP-040, MA-024 |
| State management | Zustand | WP-031, MA-023 |
| Maps | Mapbox (GL JS / Mobile SDK) | WP-050, MA-028 |

### Implementation Notes

1. **Token source of truth**: `docs/design/jila_theme_and_brand_tokens_v1.md`
2. **Web theme**: MUI 7 `createTheme()` consumes tokens via WP-014
3. **Mobile theme**: React Native Paper `configureFonts()` + custom theme per MA-022
4. **Drift prevention**: Changes to canonical tokens must update both platform themes

