# Jila Web Portal — Layout Specification (v1)

> **Status**: DECIDED  
> **Last updated**: 2026-01-14  
> **Decision reference**: WP-016  
> **Related docs**:
> - Component patterns: `./02_component_patterns_spec.md`
> - Design tokens: `./01_design_tokens_spec.md`
> - Folder structure: `../architecture/web_portal/01_folder_structure.md`
> - Shared components: `../architecture/web_portal/02_shared_components.md`

---

## 1. Overview

This document defines the **canonical layout specifications** for the Jila Web Portal. It establishes dimensions, breakpoints, and page templates that all screens must follow.

### Guiding Principles

- **Industrial clarity** (UX-P-009): Clear containers with visible edges, obvious affordances
- **Single-column preference** (UX-D-047): Reduce cognitive load; multi-column only where appropriate
- **Consistency over creativity**: Predictable layouts enable faster user comprehension
- **Mobile-responsive**: Graceful degradation from desktop to mobile

---

## 2. Core Layout Dimensions

### 2.1 Fixed Dimensions

| Element | Value | Notes |
|---------|-------|-------|
| **Topbar height** | `64px` | Fixed, always visible |
| **Sidebar expanded** | `240px` | Desktop (≥lg breakpoint) |
| **Sidebar collapsed** | `64px` | Tablet (md–lg breakpoint), icon-only |
| **Content max-width** | `1280px` | Centered within viewport |

### 2.2 Content Padding (by breakpoint)

| Breakpoint | Horizontal Padding | Vertical Padding |
|------------|-------------------|------------------|
| xs (0–599px) | `16px` | `16px` |
| sm (600–899px) | `16px` | `16px` |
| md (900–1199px) | `24px` | `24px` |
| lg (1200–1535px) | `32px` | `24px` |
| xl (≥1536px) | `32px` | `24px` |

### 2.3 MUI Theme Integration

```typescript
// app/theme/layout.ts
export const layoutTokens = {
  topbar: {
    height: 64,
  },
  sidebar: {
    widthExpanded: 240,
    widthCollapsed: 64,
  },
  content: {
    maxWidth: 1280,
    padding: {
      xs: 16,
      sm: 16,
      md: 24,
      lg: 32,
      xl: 32,
    },
  },
} as const;
```

---

## 3. Responsive Breakpoints

Using **MUI default breakpoints** (no customization):

| Breakpoint | Min Width | Sidebar State | Notes |
|------------|-----------|---------------|-------|
| `xs` | 0px | Hidden | Hamburger menu |
| `sm` | 600px | Hidden | Hamburger menu |
| `md` | 900px | Collapsed (64px) | Icon-only navigation |
| `lg` | 1200px | Expanded (240px) | Full navigation with labels |
| `xl` | 1536px | Expanded (240px) | Full navigation with labels |

### 3.1 Breakpoint Usage in MUI

```typescript
// Using sx prop
<Box sx={{ 
  display: { xs: 'none', md: 'block' },
  width: { md: 64, lg: 240 },
}} />

// Using useMediaQuery
const isDesktop = useMediaQuery(theme.breakpoints.up('lg'));
const isTablet = useMediaQuery(theme.breakpoints.between('md', 'lg'));
const isMobile = useMediaQuery(theme.breakpoints.down('md'));
```

---

## 4. Portal Shell Structure

The portal shell is the main layout wrapper for all authenticated pages.

### 4.1 Shell Composition

```
┌─────────────────────────────────────────────────────────────────┐
│                        Topbar (64px)                            │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ Logo │ Breadcrumbs/Title │         │ Search │ User Menu │   │
│  └─────────────────────────────────────────────────────────┘   │
├──────────┬──────────────────────────────────────────────────────┤
│          │                                                      │
│          │                                                      │
│  Sidebar │              Content Area                            │
│          │              (max-width: 1280px, centered)           │
│  (240px  │                                                      │
│   or     │                                                      │
│   64px)  │                                                      │
│          │                                                      │
│          │                                                      │
│          │                                                      │
└──────────┴──────────────────────────────────────────────────────┘
```

### 4.2 Shell Component Hierarchy

```
<PortalShell>
  <Topbar>
    <Logo />
    <Breadcrumbs /> (or PageTitle on mobile)
    <GlobalSearch /> (optional)
    <UserMenu />
  </Topbar>
  <Sidebar>
    <NavItems />
  </Sidebar>
  <ContentArea>
    <PageHeader />
    {children}
  </ContentArea>
</PortalShell>
```

### 4.3 Content Area Constraints

- **Max-width**: 1280px
- **Centering**: Horizontally centered when viewport > 1280px + sidebar
- **Overflow**: Vertical scroll only; horizontal scroll avoided
- **Background**: `palette.background.default`

---

## 5. Page Layout Templates

### 5.1 List Page Template

Used for: Sites list, Reservoirs list, Devices list, Alerts list, Users list

```
┌─────────────────────────────────────────────────────────────────┐
│ PageHeader                                                       │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ Title                                    │ Primary Action   │ │
│ │ Subtitle (optional)                      │ (+ Add New)      │ │
│ └─────────────────────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────────────────────┤
│ ListToolbar                                                      │
│ ┌───────────────┬─────────────────────────┬───────────────────┐ │
│ │ Search        │ Status Filters          │ Advanced Filters  │ │
│ │ [🔍 Search...] │ [All] [Active] [Risk]   │ [Filter ▼]        │ │
│ └───────────────┴─────────────────────────┴───────────────────┘ │
├─────────────────────────────────────────────────────────────────┤
│ Content                                                          │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │                                                             │ │
│ │   DataTable or CardGrid                                     │ │
│ │                                                             │ │
│ │   ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐          │ │
│ │   │ Card 1  │ │ Card 2  │ │ Card 3  │ │ Card 4  │          │ │
│ │   └─────────┘ └─────────┘ └─────────┘ └─────────┘          │ │
│ │                                                             │ │
│ └─────────────────────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────────────────────┤
│ Pagination                                                       │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │                              │ Load More │ or │ < 1 2 3 > │ │ │
│ └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

**Layout Specifications:**
- PageHeader: `mb: 3` (24px margin bottom)
- ListToolbar: `mb: 3` (24px margin bottom)
- Card grid: 1 column (xs), 2 columns (sm), 3 columns (md), 4 columns (lg+)
- Card gap: `theme.spacing(3)` (24px)
- Table: Full width with horizontal scroll on overflow

### 5.2 Detail Page Template

Used for: Site detail, Reservoir detail, Device detail, User detail

```
┌─────────────────────────────────────────────────────────────────┐
│ PageHeader (with Breadcrumbs)                                    │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ Sites > Water Plant Alpha                │ Edit │ Delete   │ │
│ └─────────────────────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────────────────────┤
│ Content (2-column on lg+, single column on md-)                  │
│ ┌─────────────────────────────────┬───────────────────────────┐ │
│ │                                 │                           │ │
│ │   Main Content                  │   Side Panel              │ │
│ │   (8/12 columns on lg+)         │   (4/12 columns on lg+)   │ │
│ │                                 │                           │ │
│ │   ┌─────────────────────────┐   │   ┌───────────────────┐   │ │
│ │   │ Details Card            │   │   │ Quick Stats       │   │ │
│ │   │ - Name: Water Plant     │   │   │ - 5 Reservoirs    │   │ │
│ │   │ - Location: Luanda      │   │   │ - 3 Devices       │   │ │
│ │   │ - Status: Active        │   │   │ - 2 Alerts        │   │ │
│ │   └─────────────────────────┘   │   └───────────────────┘   │ │
│ │                                 │                           │ │
│ │   ┌─────────────────────────┐   │   ┌───────────────────┐   │ │
│ │   │ Related Items           │   │   │ Actions           │   │ │
│ │   │ (Reservoirs list)       │   │   │ - Add Reservoir   │   │ │
│ │   │                         │   │   │ - Attach Device   │   │ │
│ │   └─────────────────────────┘   │   └───────────────────┘   │ │
│ │                                 │                           │ │
│ └─────────────────────────────────┴───────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

**Layout Specifications:**
- Main/Side split: 8/4 columns on lg+, stacked on md-
- Main content: Primary information, related lists
- Side panel: Quick stats, actions, metadata
- Gap between columns: `theme.spacing(4)` (32px)

### 5.3 Form Page Template

Used for: Create/Edit site, Create/Edit reservoir, Invite user, Manual reading

```
┌─────────────────────────────────────────────────────────────────┐
│ PageHeader (with Breadcrumbs)                                    │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ Sites > New Site                                            │ │
│ └─────────────────────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────────────────────┤
│ Content (centered, max-width: 720px)                             │
│                                                                  │
│         ┌─────────────────────────────────────────┐             │
│         │ Form Card                               │             │
│         │                                         │             │
│         │   Site Name *                           │             │
│         │   ┌─────────────────────────────────┐   │             │
│         │   │ Water Treatment Plant           │   │             │
│         │   └─────────────────────────────────┘   │             │
│         │                                         │             │
│         │   Location                              │             │
│         │   ┌─────────────────────────────────┐   │             │
│         │   │ Luanda, Angola                  │   │             │
│         │   └─────────────────────────────────┘   │             │
│         │                                         │             │
│         │   ┌───────────────┬─────────────────┐   │             │
│         │   │    Cancel     │   Save Site     │   │             │
│         │   └───────────────┴─────────────────┘   │             │
│         │                                         │             │
│         └─────────────────────────────────────────┘             │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**Layout Specifications:**
- Form max-width: 720px (narrower for readability)
- Centering: Horizontally centered
- Form card padding: `theme.spacing(4)` (32px)
- Field spacing: `theme.spacing(3)` (24px) between fields
- Button alignment: Right-aligned, Cancel (secondary) before Submit (primary)

### 5.4 Dashboard Page Template

Used for: Overview/Dashboard

```
┌─────────────────────────────────────────────────────────────────┐
│ PageHeader                                                       │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ Overview                                     │ Refresh      │ │
│ │ Organization: Jila Water Corp                │              │ │
│ └─────────────────────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────────────────────┤
│ KPI Row (4 columns on lg+, 2 on md, 1 on sm-)                    │
│ ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌───────────┐        │
│ │ Sites     │ │ Reservoirs│ │ Devices   │ │ Alerts    │        │
│ │    12     │ │    48     │ │    32     │ │    5      │        │
│ │ +2 this   │ │ 3 at risk │ │ 2 offline │ │ critical  │        │
│ │ month     │ │           │ │           │ │           │        │
│ └───────────┘ └───────────┘ └───────────┘ └───────────┘        │
├─────────────────────────────────────────────────────────────────┤
│ Widgets (2 columns on lg+, 1 on md-)                             │
│ ┌─────────────────────────────┐ ┌─────────────────────────────┐ │
│ │ Risk Overview               │ │ Sites Map                   │ │
│ │                             │ │                             │ │
│ │  ┌─────────────────────┐    │ │   ┌─────────────────────┐   │ │
│ │  │ Risk chart/         │    │ │   │                     │   │ │
│ │  │ distribution        │    │ │   │   [Map]             │   │ │
│ │  │                     │    │ │   │                     │   │ │
│ │  └─────────────────────┘    │ │   └─────────────────────┘   │ │
│ │                             │ │                             │ │
│ └─────────────────────────────┘ └─────────────────────────────┘ │
├─────────────────────────────────────────────────────────────────┤
│ Recent Activity (full width)                                     │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ Recent Alerts                                │ View All →   │ │
│ │ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐            │ │
│ │ │ Alert 1 │ │ Alert 2 │ │ Alert 3 │ │ Alert 4 │            │ │
│ │ └─────────┘ └─────────┘ └─────────┘ └─────────┘            │ │
│ └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

**Layout Specifications:**
- KPI cards: Equal width, 4 columns on lg+, 2 on md, 1 on sm-
- KPI card height: Auto (content-driven), min-height: 120px
- Widget row: 6/6 split on lg+, full width stacked on md-
- Widget min-height: 300px
- Gap: `theme.spacing(3)` (24px) between all cards

---

## 6. Sidebar Navigation

### 6.1 Navigation Items

| Label | Icon | Route | Sub-items |
|-------|------|-------|-----------|
| Overview | `dashboard` | `/dashboard` | — |
| Sites | `location_city` | `/sites` | — |
| Reservoirs | `water_drop` | `/reservoirs` | — |
| Devices | `sensors` | `/devices` | — |
| Alerts | `notifications` | `/alerts` | Badge with unread count |
| Users & Access | `group` | `/users` | — |
| Settings | `settings` | `/settings` | Profile, Notifications, Organization |

### 6.2 Sidebar States

**Expanded (240px):**
```
┌──────────────────────────────┐
│  [Logo]  Jila                │
├──────────────────────────────┤
│  🏠  Overview                │
│  🏢  Sites                   │
│  💧  Reservoirs              │
│  📡  Devices                 │
│  🔔  Alerts           (3)    │  ← Badge for unread
│  👥  Users & Access          │
├──────────────────────────────┤
│  ⚙️  Settings                │
└──────────────────────────────┘
```

**Collapsed (64px):**
```
┌────────┐
│  [J]   │  ← Logo icon only
├────────┤
│   🏠   │  ← Tooltip: "Overview"
│   🏢   │
│   💧   │
│   📡   │
│  🔔(3) │  ← Badge persists
│   👥   │
├────────┤
│   ⚙️   │
└────────┘
```

### 6.3 Active State Styling

Per UX-D-022 (Navigation anchors), active state must be visible without relying on color alone:

```typescript
// Active nav item styling
{
  backgroundColor: 'rgba(78, 205, 196, 0.12)', // primary tint
  borderLeft: '3px solid', // Solid indicator
  borderLeftColor: 'primary.main',
  fontWeight: 600, // Label weight change
  '& .MuiListItemIcon-root': {
    color: 'primary.main',
  },
}
```

---

## 7. Topbar Structure

### 7.1 Topbar Composition

```
┌─────────────────────────────────────────────────────────────────┐
│ [≡] │ [Logo] │ Breadcrumbs / Page Title │    │ [🔍] │ [👤 ▼] │
│     │        │                           │    │      │        │
│ Ham-│ Logo   │ Dynamic based on route    │Flex│Search│ User   │
│ burg│ (link  │                           │    │      │ Menu   │
│ er  │ home)  │                           │    │      │        │
└─────────────────────────────────────────────────────────────────┘
  ↑                                                         ↑
  Mobile only (< md)                              Always visible
```

### 7.2 Topbar Dimensions

| Element | Width | Notes |
|---------|-------|-------|
| Hamburger | 48px | Mobile only |
| Logo | 120px | Scales down on mobile |
| Breadcrumbs | Flex | Takes remaining space |
| Search | 48px (icon) / 280px (expanded) | Optional, collapsible |
| User menu | 48px | Avatar + dropdown |

### 7.3 Breadcrumb Pattern

```typescript
// Route: /sites/abc123/edit
// Breadcrumbs: Sites > Water Plant Alpha > Edit

<Breadcrumbs>
  <Link href="/sites">Sites</Link>
  <Link href="/sites/abc123">Water Plant Alpha</Link>
  <Typography>Edit</Typography> {/* Current page, no link */}
</Breadcrumbs>
```

---

## 8. Grid System

Using MUI Grid v2 with 12-column layout.

### 8.1 Common Grid Patterns

**Card Grid (4 columns on lg):**
```typescript
<Grid container spacing={3}>
  {items.map((item) => (
    <Grid key={item.id} size={{ xs: 12, sm: 6, md: 4, lg: 3 }}>
      <EntityCard {...item} />
    </Grid>
  ))}
</Grid>
```

**Detail Page (8/4 split):**
```typescript
<Grid container spacing={4}>
  <Grid size={{ xs: 12, lg: 8 }}>
    <MainContent />
  </Grid>
  <Grid size={{ xs: 12, lg: 4 }}>
    <SidePanel />
  </Grid>
</Grid>
```

**Dashboard Widgets (6/6 split):**
```typescript
<Grid container spacing={3}>
  <Grid size={{ xs: 12, lg: 6 }}>
    <RiskOverviewWidget />
  </Grid>
  <Grid size={{ xs: 12, lg: 6 }}>
    <SitesMapWidget />
  </Grid>
</Grid>
```

### 8.2 Spacing Values

| Context | Spacing | Value |
|---------|---------|-------|
| Card grid | `spacing={3}` | 24px |
| Detail page columns | `spacing={4}` | 32px |
| Form fields | `spacing={3}` | 24px |
| KPI cards | `spacing={3}` | 24px |
| Tight lists | `spacing={2}` | 16px |

---

## 9. Z-Index Layering

| Layer | z-index | Components |
|-------|---------|------------|
| Base content | 0 | Page content |
| Elevated cards | 1 | Cards with shadow |
| Sticky elements | 100 | Sticky table headers |
| Sidebar | 1100 | MUI Drawer default |
| Topbar | 1200 | MUI AppBar default |
| Modals/Dialogs | 1300 | MUI Modal default |
| Snackbars | 1400 | MUI Snackbar default |
| Tooltips | 1500 | MUI Tooltip default |

---

## 10. Implementation Checklist

### Layout Components to Implement

- [ ] `PortalShell` — Main layout wrapper
- [ ] `Sidebar` — Navigation drawer (collapsible)
- [ ] `Topbar` — App bar with breadcrumbs
- [ ] `ContentContainer` — Max-width wrapper with padding
- [ ] `PageHeader` — Consistent page titles and actions
- [ ] `ListToolbar` — Search + filters + actions

### Theme Configuration

- [ ] Add `layoutTokens` to theme
- [ ] Configure responsive breakpoints (MUI defaults)
- [ ] Set up sidebar width CSS custom properties
- [ ] Configure z-index layering

### Testing

- [ ] Verify sidebar collapse at md breakpoint
- [ ] Verify sidebar hidden at sm breakpoint
- [ ] Verify content max-width at xl viewport
- [ ] Verify form centering at all breakpoints
- [ ] Test with keyboard navigation

---

## 11. References

- MUI Breakpoints: https://mui.com/material-ui/customization/breakpoints/
- MUI Grid v2: https://mui.com/material-ui/react-grid2/
- Design tokens: `./01_design_tokens_spec.md`
- Component patterns: `./02_component_patterns_spec.md`
