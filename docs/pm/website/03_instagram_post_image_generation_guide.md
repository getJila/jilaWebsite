# Instagram Post Image Generation Guide

> How to create on-brand Instagram posts using the HTML overlay template.

---

## Overview

Instead of editing product images directly in a design tool, we use an HTML template (`instagram-post.html`) that composites text overlays on top of any background image. The HTML is then exported as a pixel-perfect 1080×1080 PNG ready for Instagram.

**Why this approach?**

- No design software required — just a browser and a text editor
- Brand tokens (colours, fonts, spacing) are enforced by CSS
- Repeatable: swap the image, tweak the copy, export
- Version-controlled alongside the website codebase

---

## Prerequisites

| Requirement | Detail |
|---|---|
| **Browser** | Chrome or Edge (recommended for html2canvas compatibility) |
| **Local server** | Required — `file://` protocol blocks image export |
| **Image** | PNG or JPG, at least 1080×1080px, placed in the repo root |
| **Fonts** | Loaded from Google Fonts (IBM Plex Sans / IBM Plex Mono) — needs internet |

---

## Quick Start

### 1. Place your background image

Copy your product photo into the repo root:

```
/jilaWebsite/
  ├── instagram-post.html
  ├── your-image.png        ← place here
  └── ...
```

### 2. Update the image source

Open `instagram-post.html` and find this line:

```html
<img class="bg-image" src="testimage.png" alt="Jila Product">
```

Change `testimage.png` to your image filename:

```html
<img class="bg-image" src="your-image.png" alt="Jila Product">
```

### 3. Update the overlay text

The text content is in the `<!-- Bottom -->` section of the HTML. The key editable elements:

| Element | CSS Class | Purpose |
|---|---|---|
| Status pill | `.coming-soon-label` | "Em Breve" badge with pulsing dot |
| Headline | `.headline` | Main message (52px, bold) |
| Accent text | `.headline .accent` | Teal-coloured portion of headline |
| Subheadline | `.subheadline` | Supporting description (22px) |
| Website | `.website` | Bottom-left URL (mono font) |
| Tagline | `.tagline` | Bottom-right label (mono font) |
| Badge | `.badge` | Top-right pill (e.g. "2026") |

Example — changing the headline:

```html
<h1 class="headline">
    Your main message here<br>
    <span class="accent">accented second line.</span>
</h1>
```

### 4. Start the local server

From the repo root, run:

```bash
python3 -m http.server 8090
```

### 5. Open in browser

Navigate to:

```
http://localhost:8090/instagram-post.html
```

### 6. Export the image

Click the **"⬇ Download como PNG"** button. The file `jila-instagram-post.png` will download to your default downloads folder.

---

## Instagram Image Specifications

Per [Instagram's official documentation](https://help.instagram.com/1631821640426723/):

| Parameter | Value |
|---|---|
| **Format** | PNG (lossless) |
| **Dimensions** | 1080 × 1080 px (square) |
| **Aspect ratio** | 1:1 (supported range: 1.91:1 to 3:4) |
| **Max width preserved** | 1080 px — images wider than this are downscaled |
| **Min width** | 320 px — images narrower are upscaled (avoid this) |

The template exports at exactly 1080×1080px to match Instagram's native resolution.

---

## Export Quality Pipeline

The export process ensures maximum sharpness:

```
html2canvas captures at 2× (2160 × 2160)
        │
        ▼
Canvas downscale with bicubic smoothing
        │
        ▼
Final PNG at 1080 × 1080 (max quality)
```

1. **Capture at 2×** — renders all text and graphics at double resolution, picking up sub-pixel detail
2. **Downscale to 1080×1080** — uses `imageSmoothingQuality: 'high'` for clean anti-aliasing
3. **PNG encoding at quality 1.0** — lossless output with no JPEG artefacts

---

## Template Structure

```
instagram-post.html
│
├── #post (1080×1080 canvas)
│   ├── .bg-image          ← your product photo
│   ├── .overlay            ← gradient for text legibility
│   └── .content            ← text overlay layer
│       ├── .top-area
│       │   ├── .logo       ← Jila logo + wordmark
│       │   └── .badge      ← year/status pill
│       └── .bottom-area
│           ├── .coming-soon-label
│           ├── .headline
│           ├── .subheadline
│           ├── .divider
│           └── .footer-line (website + tagline)
│
└── .download-section       ← export button (outside canvas)
```

---

## Brand Tokens Used

| Token | Value | Usage |
|---|---|---|
| Midnight | `#0B1A2E` | Canvas background, overlay gradient |
| Teal Primary | `#2A9DB5` | Accent text, divider |
| Teal Light | `#3CC0D8` | Badges, pills, logo icon |
| White | `#FFFFFF` | Headline, logo text |
| IBM Plex Sans | 400–700 | Headlines, subheadlines |
| IBM Plex Mono | 400–500 | Badges, labels, website URL |

---

## Customisation Guide

### Adjusting the gradient overlay

The gradient controls how much the background image is dimmed. Edit the `.overlay` CSS:

```css
#post .overlay {
    background: linear-gradient(
        180deg,
        rgba(11, 26, 46, 0.55) 0%,    /* top — moderate dim */
        rgba(11, 26, 46, 0.15) 35%,   /* upper-mid — light */
        rgba(11, 26, 46, 0.10) 55%,   /* center — very light */
        rgba(11, 26, 46, 0.65) 80%,   /* lower-mid — darker */
        rgba(11, 26, 46, 0.90) 100%   /* bottom — heavy (text area) */
    );
}
```

- **More visible image**: reduce the alpha values (e.g. `0.55` → `0.30`)
- **Better text contrast**: increase the bottom values (e.g. `0.90` → `0.95`)

### Changing canvas size for Stories

For Instagram Stories (1080×1920), update the `#post` dimensions:

```css
#post {
    width: 1080px;
    height: 1920px;  /* 9:16 aspect ratio */
}
```

And update the html2canvas call accordingly:

```js
html2canvas(post, {
    scale: 2,
    width: 1080,
    height: 1920,
    ...
})
```

### Removing the "Coming Soon" badge

Delete or comment out this block in the HTML:

```html
<div class="coming-soon-label">
    <span class="dot"></span>
    Em Breve
</div>
```

---

## Troubleshooting

| Problem | Cause | Fix |
|---|---|---|
| Download button does nothing | Opened via `file://` protocol | Start a local HTTP server (step 4) |
| Export alert "Falha ao exportar" | Image CORS blocked | Ensure you're using `http://localhost:...` |
| Blurry/grainy text in export | Browser DPI mismatch | Already handled by 2× capture + downscale pipeline |
| Fonts not loading | No internet connection | Connect to load Google Fonts, or install IBM Plex locally |
| Image not showing | Wrong filename in `src` | Check the `<img>` tag matches your file exactly |

---

## File Naming Convention

Export files should follow this pattern:

```
jila-instagram-{purpose}-{date}.png
```

Examples:
- `jila-instagram-coming-soon-2026-02.png`
- `jila-instagram-product-launch-2026-03.png`
- `jila-instagram-feature-alert-2026-04.png`
