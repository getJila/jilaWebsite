# Jila Web Portal — Folder Structure Architecture (v1)

> **Status**: DECIDED  
> **Last updated**: 2026-01-14  
> **Decision references**: WP-012, WP-013, WP-014, WP-016, WP-017, WP-030–040  
> **Related docs**:
> - **Shared components catalog**: `./02_shared_components.md`
> - **Layout spec**: `../../design/03_web_layout_spec.md`
> - Design tokens: `../../design/01_design_tokens_spec.md`
> - Component patterns: `../../design/02_component_patterns_spec.md`
> - Decision register: `../../decision_registers/web_portal_decision_register.md`
> - PRD: `../../pm/web_portal/01_web_portal_prd.md`

---

## 1. Overview

This document defines the **canonical folder structure** for the Jila Web Portal, a Next.js 15 App Router application. It serves as the authoritative reference for:

- Where files and folders should be placed
- Naming conventions for files, components, and modules
- How features are organized (feature-based architecture)
- Integration with Next.js App Router conventions

### Guiding Principles

1. **Feature-based organization** — Group by domain, not by file type
2. **Colocation** — Keep related files together (component + types + tests)
3. **Single Responsibility** — Each file has one clear purpose; max 700 lines
4. **Explicit over implicit** — Clear naming, predictable locations
5. **MUI-only UI** — All components use MUI 7 (see WP-012)

---

## 2. Top-Level Structure

```
jilaPortalFrontend/
├── app/                        # Next.js App Router root
│   ├── [locale]/               # Internationalized routes
│   ├── api/                    # API route handlers
│   ├── features/               # Feature modules (business logic)
│   ├── shared/                 # Cross-cutting shared code
│   └── theme/                  # MUI theme configuration
│
├── i18n/                       # Internationalization config (next-intl)
│   ├── messages/               # Translation JSON files
│   ├── routing.ts              # Locale routing config
│   ├── navigation.ts           # Localized navigation helpers
│   └── request.ts              # Server-side i18n
│
├── public/                     # Static assets (images, fonts, icons)
│   ├── fonts/                  # Custom fonts (IBM Plex Sans, Silka Mono)
│   ├── images/                 # Static images
│   └── icons/                  # Favicon, app icons
│
├── e2e/                        # Playwright E2E tests
│   ├── fixtures/               # Test fixtures and utilities
│   └── *.spec.ts               # Test files
│
├── docs/                       # Documentation (existing)
│
├── .worktrees/                 # Git worktrees (gitignored)
│
├── middleware.ts               # Auth + i18n middleware
├── next.config.ts              # Next.js configuration
├── tsconfig.json               # TypeScript configuration
├── package.json                # Dependencies
├── playwright.config.ts        # Playwright configuration
└── .env.local                  # Environment variables (gitignored)
```

---

## 3. App Directory Structure

### 3.1 Route Structure (`app/[locale]/`)

The `[locale]` dynamic segment enables internationalization via `next-intl`.

```
app/
├── [locale]/                           # Dynamic locale (pt-AO, en-US)
│   ├── layout.tsx                      # Root layout (ThemeProvider, QueryProvider)
│   ├── page.tsx                        # Root redirect → /dashboard
│   ├── not-found.tsx                   # 404 page
│   ├── error.tsx                       # Error boundary
│   ├── loading.tsx                     # Root loading state
│   │
│   ├── (auth)/                         # Auth route group (no shell)
│   │   ├── layout.tsx                  # Minimal auth layout
│   │   ├── login/
│   │   │   └── page.tsx                # Login page
│   │   ├── logout/
│   │   │   └── page.tsx                # Logout handler
│   │   ├── invite/
│   │   │   └── [token]/
│   │   │       └── page.tsx            # Invite acceptance
│   │   ├── forgot-password/
│   │   │   └── page.tsx                # Password reset request
│   │   └── reset-password/
│   │       └── [token]/
│   │           └── page.tsx            # Password reset form
│   │
│   ├── (portal)/                       # Main portal route group (with shell)
│   │   ├── layout.tsx                  # Portal shell (sidebar + topbar)
│   │   │
│   │   ├── dashboard/
│   │   │   └── page.tsx                # Dashboard/Overview
│   │   │
│   │   ├── sites/
│   │   │   ├── page.tsx                # Sites list
│   │   │   ├── new/
│   │   │   │   └── page.tsx            # Create site
│   │   │   └── [siteId]/
│   │   │       ├── page.tsx            # Site detail
│   │   │       └── edit/
│   │   │           └── page.tsx        # Edit site
│   │   │
│   │   ├── reservoirs/
│   │   │   ├── page.tsx                # Reservoirs list
│   │   │   └── [reservoirId]/
│   │   │       ├── page.tsx            # Reservoir detail
│   │   │       ├── edit/
│   │   │       │   └── page.tsx        # Edit reservoir
│   │   │       └── readings/
│   │   │           ├── page.tsx        # Readings history
│   │   │           └── new/
│   │   │               └── page.tsx    # Manual reading form
│   │   │
│   │   ├── devices/
│   │   │   ├── page.tsx                # Devices list
│   │   │   └── [deviceId]/
│   │   │       ├── page.tsx            # Device detail
│   │   │       └── config/
│   │   │           └── page.tsx        # Device config view
│   │   │
│   │   ├── alerts/
│   │   │   ├── page.tsx                # Alerts feed
│   │   │   └── [alertId]/
│   │   │       └── page.tsx            # Alert detail (optional)
│   │   │
│   │   ├── users/
│   │   │   ├── page.tsx                # Users & access list
│   │   │   ├── invite/
│   │   │   │   └── page.tsx            # Invite user form
│   │   │   └── [userId]/
│   │   │       └── page.tsx            # User detail/scope view
│   │   │
│   │   └── settings/
│   │       ├── page.tsx                # Settings overview
│   │       ├── profile/
│   │       │   └── page.tsx            # Profile settings
│   │       ├── notifications/
│   │       │   └── page.tsx            # Notification preferences
│   │       └── organization/
│   │           └── page.tsx            # Org settings (Owner only)
│   │
│   └── (onboarding)/                   # Onboarding route group
│       ├── layout.tsx                  # Onboarding-specific layout
│       └── org-bootstrap/
│           └── page.tsx                # Org bootstrap wizard
│
├── api/                                # API route handlers
│   ├── auth/
│   │   └── [...nextauth]/
│   │       └── route.ts                # NextAuth.js handler
│   └── v1/
│       └── [...path]/
│           └── route.ts                # Proxy to backend API
│
├── features/                           # Feature modules (see Section 4)
├── shared/                             # Shared code (see Section 5)
└── theme/                              # Theme config (see Section 6)
```

### 3.2 Route Groups Explained

| Group | Purpose | Layout |
|-------|---------|--------|
| `(auth)` | Authentication flows | Minimal, no navigation shell |
| `(portal)` | Main application | Full shell with sidebar + topbar |
| `(onboarding)` | First-time setup | Wizard-style, guided flow |

### 3.3 Route File Conventions

| File | Purpose |
|------|---------|
| `page.tsx` | Route UI (required for route to be accessible) |
| `layout.tsx` | Shared UI wrapper for route and children |
| `loading.tsx` | Loading UI (Suspense fallback) |
| `error.tsx` | Error boundary UI |
| `not-found.tsx` | 404 UI |

---

## 4. Feature Modules (`app/features/`)

Features contain **business logic, API calls, and feature-specific components**. Route pages (`page.tsx`) import from features but remain thin.

### 4.1 Feature Module Structure

Each feature follows this template:

```
features/
├── dashboard/
│   ├── components/                 # Feature-specific components
│   │   ├── DashboardHeader.tsx
│   │   ├── KpiCard.tsx
│   │   ├── RiskOverview.tsx
│   │   ├── SitesSummary.tsx
│   │   └── FreshnessIndicator.tsx
│   ├── hooks/                      # Feature-specific hooks
│   │   └── useDashboardFilters.ts
│   ├── queries.ts                  # TanStack Query hooks
│   ├── api.ts                      # API functions
│   ├── types.ts                    # Feature types
│   ├── utils.ts                    # Feature utilities
│   ├── constants.ts                # Feature constants
│   └── index.ts                    # Public exports
│
├── sites/
│   ├── components/
│   │   ├── SiteCard.tsx
│   │   ├── SiteForm.tsx
│   │   ├── SiteList.tsx
│   │   ├── SiteMap.tsx
│   │   ├── SiteDetail.tsx
│   │   └── SiteFilters.tsx
│   ├── hooks/
│   │   ├── useSiteFilters.ts
│   │   └── useSiteMap.ts
│   ├── queries.ts
│   ├── api.ts
│   ├── types.ts
│   ├── schemas.ts                  # Zod validation schemas
│   └── index.ts
│
├── reservoirs/
│   ├── components/
│   │   ├── ReservoirCard.tsx
│   │   ├── ReservoirDetail.tsx
│   │   ├── ReservoirForm.tsx
│   │   ├── ReservoirList.tsx
│   │   ├── ReadingsChart.tsx
│   │   ├── ReadingsHistory.tsx
│   │   ├── ManualReadingForm.tsx
│   │   ├── WaterLevelIndicator.tsx
│   │   └── FreshnessWarning.tsx
│   ├── hooks/
│   │   ├── useReservoirFilters.ts
│   │   └── useReadingsChart.ts
│   ├── queries.ts
│   ├── api.ts
│   ├── types.ts
│   ├── schemas.ts
│   └── index.ts
│
├── devices/
│   ├── components/
│   │   ├── DeviceCard.tsx
│   │   ├── DeviceDetail.tsx
│   │   ├── DeviceList.tsx
│   │   ├── DeviceConfigView.tsx
│   │   ├── PairingStatus.tsx
│   │   ├── AttachDeviceDialog.tsx
│   │   └── DetachDeviceDialog.tsx
│   ├── hooks/
│   │   └── useDeviceFilters.ts
│   ├── queries.ts
│   ├── api.ts
│   ├── types.ts
│   └── index.ts
│
├── alerts/
│   ├── components/
│   │   ├── AlertCard.tsx
│   │   ├── AlertFeed.tsx
│   │   ├── AlertFilters.tsx
│   │   ├── AlertDetail.tsx
│   │   └── AlertBadge.tsx
│   ├── hooks/
│   │   ├── useAlertFilters.ts
│   │   └── useUnreadCount.ts
│   ├── queries.ts
│   ├── api.ts
│   ├── types.ts
│   └── index.ts
│
├── users/
│   ├── components/
│   │   ├── UserCard.tsx
│   │   ├── UserList.tsx
│   │   ├── UserDetail.tsx
│   │   ├── InviteUserForm.tsx
│   │   ├── ScopeDisplay.tsx
│   │   ├── RoleBadge.tsx
│   │   └── RevokeAccessDialog.tsx
│   ├── hooks/
│   │   └── useUserFilters.ts
│   ├── queries.ts
│   ├── api.ts
│   ├── types.ts
│   ├── schemas.ts
│   └── index.ts
│
├── settings/
│   ├── components/
│   │   ├── ProfileForm.tsx
│   │   ├── LanguagePicker.tsx
│   │   ├── NotificationPreferences.tsx
│   │   ├── OrganizationSettings.tsx
│   │   └── SubscriptionView.tsx
│   ├── queries.ts
│   ├── api.ts
│   ├── types.ts
│   ├── schemas.ts
│   └── index.ts
│
└── auth/
    ├── components/
    │   ├── LoginForm.tsx
    │   ├── ForgotPasswordForm.tsx
    │   ├── ResetPasswordForm.tsx
    │   ├── InviteAcceptForm.tsx
    │   └── SessionExpiredDialog.tsx
    ├── hooks/
    │   ├── useAuth.ts
    │   └── useSession.ts
    ├── queries.ts
    ├── api.ts
    ├── types.ts
    ├── schemas.ts
    └── index.ts
```

### 4.2 Feature File Responsibilities

| File | Purpose | Example |
|------|---------|---------|
| `components/` | Feature-specific UI components | `SiteCard.tsx`, `SiteForm.tsx` |
| `hooks/` | Feature-specific React hooks | `useSiteFilters.ts` |
| `queries.ts` | TanStack Query hooks (`useQuery`, `useMutation`) | `useSitesQuery()`, `useCreateSiteMutation()` |
| `api.ts` | Raw API functions (used by queries) | `fetchSites()`, `createSite()` |
| `types.ts` | TypeScript interfaces and types | `Site`, `SiteFormValues` |
| `schemas.ts` | Zod validation schemas | `siteFormSchema` |
| `utils.ts` | Feature-specific utility functions | `formatSiteAddress()` |
| `constants.ts` | Feature-specific constants | `SITE_STATUS_OPTIONS` |
| `index.ts` | Public exports (barrel file) | Re-export components, hooks, types |

### 4.3 Query File Pattern (`queries.ts`)

```typescript
// features/sites/queries.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { fetchSites, fetchSite, createSite, updateSite, deleteSite } from './api';
import type { Site, CreateSiteInput, UpdateSiteInput } from './types';

// Query keys
export const siteKeys = {
  all: ['sites'] as const,
  lists: () => [...siteKeys.all, 'list'] as const,
  list: (filters: SiteFilters) => [...siteKeys.lists(), filters] as const,
  details: () => [...siteKeys.all, 'detail'] as const,
  detail: (id: string) => [...siteKeys.details(), id] as const,
};

// Queries
export function useSitesQuery(filters?: SiteFilters) {
  return useQuery({
    queryKey: siteKeys.list(filters ?? {}),
    queryFn: () => fetchSites(filters),
  });
}

export function useSiteQuery(id: string) {
  return useQuery({
    queryKey: siteKeys.detail(id),
    queryFn: () => fetchSite(id),
    enabled: !!id,
  });
}

// Mutations
export function useCreateSiteMutation() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (input: CreateSiteInput) => createSite(input),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: siteKeys.lists() });
    },
  });
}
```

---

## 5. Shared Code (`app/shared/`)

Cross-cutting code used by multiple features.

> **Component Catalog**: See `./02_shared_components.md` for the complete shared component catalog with props, usage guidelines, and implementation priority.

```
shared/
├── ui/                                 # Shared UI components (per WP-017)
│   ├── badges/                         # Status & badge components
│   │   ├── StatusBadge.tsx             # Generic status (user, order, invite, etc.)
│   │   ├── SeverityBadge.tsx           # Alert severity (critical, warning, info)
│   │   ├── RiskLevelBadge.tsx          # Site risk (critical, warning, stale, good)
│   │   ├── LevelStateBadge.tsx         # Reservoir level (full, normal, low, critical)
│   │   ├── ConnectivityBadge.tsx       # Device connectivity (online, offline, stale)
│   │   ├── RoleBadge.tsx               # User role (owner, manager, viewer)
│   │   └── index.ts
│   │
│   ├── data-display/                   # Data display components
│   │   ├── TimestampDisplay.tsx        # Relative/absolute timestamps
│   │   ├── FreshnessIndicator.tsx      # Data freshness with stale warnings
│   │   ├── PercentageIndicator.tsx     # Level/battery percentages
│   │   ├── CountBadge.tsx              # Counts with labels
│   │   ├── KpiValue.tsx                # Dashboard KPI display
│   │   └── index.ts
│   │
│   ├── identity/                       # Identity/profile components
│   │   ├── ProfileAvatar.tsx           # User avatar with fallback
│   │   ├── UserInfo.tsx                # Name, email, role display
│   │   └── index.ts
│   │
│   ├── layout/                         # Layout components (per WP-016)
│   │   ├── PortalShell.tsx             # Main layout wrapper
│   │   ├── Sidebar.tsx                 # Navigation sidebar
│   │   ├── Topbar.tsx                  # App bar with breadcrumbs
│   │   ├── ContentContainer.tsx        # Max-width content wrapper
│   │   ├── PageHeader.tsx              # Page title, subtitle, actions
│   │   ├── ListToolbar.tsx             # Search, filters, primary action
│   │   └── index.ts
│   │
│   ├── state/                          # State components (per UX-D-049)
│   │   ├── EmptyState.tsx              # Empty state with CTA
│   │   ├── LoadingSkeleton.tsx         # Skeleton placeholders
│   │   ├── ErrorDisplay.tsx            # Error with retry action
│   │   ├── LoadingOverlay.tsx          # Mutation in-progress overlay
│   │   └── index.ts
│   │
│   ├── lists/                          # List & card components
│   │   ├── PaginatedList.tsx           # Cursor-based pagination
│   │   ├── EntityCard.tsx              # Base entity card
│   │   ├── DataTable.tsx               # MUI DataGrid wrapper
│   │   └── index.ts
│   │
│   └── index.ts                        # Main barrel export
│
├── form/                               # Form primitives (React Hook Form + MUI)
│   ├── FormTextField.tsx               # Text field with RHF
│   ├── FormSelect.tsx                  # Select field with RHF
│   ├── FormDatePicker.tsx              # Date picker with RHF
│   ├── FormSwitch.tsx                  # Switch/toggle with RHF
│   ├── FormError.tsx                   # Form-level error display
│   └── index.ts
│
├── hooks/                              # Reusable hooks
│   ├── useDebounce.ts
│   ├── useMediaQuery.ts
│   ├── useLocalStorage.ts
│   ├── useDisclosure.ts                # Modal/dialog open state
│   ├── usePagination.ts
│   └── index.ts
│
├── lib/                                # Utility libraries
│   ├── date.ts                         # date-fns helpers
│   ├── format.ts                       # Formatting utilities
│   ├── validation.ts                   # Shared Zod schemas
│   └── index.ts
│
├── api/                                # API infrastructure
│   ├── client.ts                       # HTTP client (fetch wrapper)
│   ├── errors.ts                       # Error types and handlers
│   ├── types.ts                        # API response types
│   └── index.ts
│
├── types/                              # Global types
│   ├── common.ts                       # Common types (Pagination, etc.)
│   ├── api.ts                          # API types
│   └── index.ts
│
└── constants/                          # Global constants
    ├── routes.ts                       # Route path constants
    ├── config.ts                       # App configuration
    └── index.ts
```

### 5.1 Component Placement Rules (per WP-017)

| Scenario | Location | Example |
|----------|----------|---------|
| Used by 2+ features | `shared/ui/<category>/` | `StatusBadge`, `PageHeader` |
| Feature-specific | `features/<feature>/components/` | `SiteMap`, `ReadingsChart` |
| MUI thin wrapper | `shared/ui/<category>/` | Wraps MUI with project defaults |
| Form field | `shared/form/` | `FormTextField`, `FormSelect` |

### 5.2 Import Patterns

```typescript
// Import from category barrel (preferred)
import { StatusBadge, RiskLevelBadge } from '@/shared/ui/badges';
import { PageHeader, ContentContainer } from '@/shared/ui/layout';
import { EmptyState, LoadingSkeleton } from '@/shared/ui/state';

// Import from main barrel (also valid)
import { StatusBadge, PageHeader, EmptyState } from '@/shared/ui';

// Form components
import { FormTextField, FormSelect } from '@/shared/form';
```

---

## 6. Theme Configuration (`app/theme/`)

MUI theme implementing design tokens (per WP-014, WP-090).

```
theme/
├── theme.ts                    # Main theme configuration
├── palette.ts                  # Color palette (light + dark)
├── typography.ts               # Typography variants
├── components.ts               # Component overrides
├── augmentation.d.ts           # TypeScript module augmentation
└── index.ts                    # Exports
```

### 6.1 Theme Provider Integration

The theme is provided at the root layout:

```typescript
// app/[locale]/layout.tsx
import { ThemeProvider } from '@mui/material/styles';
import CssBaseline from '@mui/material/CssBaseline';
import { theme } from '@/app/theme';

export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        <ThemeProvider theme={theme}>
          <CssBaseline />
          {children}
        </ThemeProvider>
      </body>
    </html>
  );
}
```

---

## 7. Internationalization (`i18n/`)

Configuration for `next-intl` with pt-AO (default) and en-US locales.

```
i18n/
├── routing.ts                  # Locale routing configuration
├── navigation.ts               # Localized Link, useRouter, etc.
├── request.ts                  # Server-side i18n (getRequestConfig)
│
└── messages/                   # Translation files (JSON)
    ├── en-US/
    │   ├── common.json         # Shared strings
    │   ├── auth.json           # Auth feature strings
    │   ├── dashboard.json      # Dashboard feature strings
    │   ├── sites.json          # Sites feature strings
    │   ├── reservoirs.json     # Reservoirs feature strings
    │   ├── devices.json        # Devices feature strings
    │   ├── alerts.json         # Alerts feature strings
    │   ├── users.json          # Users feature strings
    │   ├── settings.json       # Settings feature strings
    │   ├── navigation.json     # Navigation labels
    │   ├── validation.json     # Validation messages
    │   └── orgBootstrap.json   # Onboarding strings
    │
    └── pt-AO/
        ├── common.json
        ├── auth.json
        ├── dashboard.json
        ├── sites.json
        ├── reservoirs.json
        ├── devices.json
        ├── alerts.json
        ├── users.json
        ├── settings.json
        ├── navigation.json
        ├── validation.json
        └── orgBootstrap.json
```

### 7.1 Message Namespace Convention

Each feature has its own message namespace file. Import with:

```typescript
import { useTranslations } from 'next-intl';

function SiteCard() {
  const t = useTranslations('sites');
  return <h1>{t('card.title')}</h1>;
}
```

---

## 8. E2E Tests (`e2e/`)

Playwright tests organized by feature.

```
e2e/
├── fixtures/
│   ├── auth.ts                 # Auth fixtures (login helper)
│   ├── test-data.ts            # Test data generators
│   └── index.ts
│
├── auth.spec.ts                # Auth flow tests
├── dashboard.spec.ts           # Dashboard tests
├── sites.spec.ts               # Sites CRUD tests
├── reservoirs.spec.ts          # Reservoirs tests
├── devices.spec.ts             # Devices tests
├── alerts.spec.ts              # Alerts tests
├── users.spec.ts               # Users & access tests
├── settings.spec.ts            # Settings tests
└── visual-parity.spec.ts       # Visual regression tests
```

---

## 9. Naming Conventions

### 9.1 Files

| Type | Convention | Example |
|------|------------|---------|
| Components | PascalCase | `SiteCard.tsx` |
| Hooks | camelCase with `use` prefix | `useSiteFilters.ts` |
| Utilities | camelCase | `formatDate.ts` |
| Types | camelCase | `types.ts` |
| Constants | camelCase | `constants.ts` |
| Route pages | `page.tsx` (Next.js convention) | `app/[locale]/(portal)/sites/page.tsx` |

### 9.2 Components

| Type | Convention | Example |
|------|------------|---------|
| Component name | PascalCase | `SiteCard` |
| Props interface | `ComponentNameProps` | `SiteCardProps` |
| Event handlers | `handle` prefix | `handleSubmit`, `handleDelete` |

### 9.3 Hooks

| Type | Convention | Example |
|------|------------|---------|
| Query hooks | `use[Entity]Query` | `useSitesQuery`, `useSiteQuery` |
| Mutation hooks | `use[Action][Entity]Mutation` | `useCreateSiteMutation` |
| Other hooks | `use[Purpose]` | `useSiteFilters`, `useDebounce` |

### 9.4 Types

| Type | Convention | Example |
|------|------------|---------|
| Entity types | PascalCase | `Site`, `Reservoir`, `Device` |
| Form values | `[Entity]FormValues` | `SiteFormValues` |
| API inputs | `[Action][Entity]Input` | `CreateSiteInput` |
| API responses | `[Entity]Response` | `SiteResponse` |
| Filter types | `[Entity]Filters` | `SiteFilters` |

---

## 10. Path Aliases

Configured in `tsconfig.json`:

```json
{
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@/*": ["./*"],
      "@/app/*": ["app/*"],
      "@/shared/*": ["app/shared/*"],
      "@/features/*": ["app/features/*"],
      "@/i18n/*": ["i18n/*"]
    }
  }
}
```

### 10.1 Import Examples

```typescript
// External dependencies first
import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useTranslations } from 'next-intl';

// Shared UI components
import { Button, Card } from '@/shared/ui';
import { Link } from '@/i18n/navigation';

// Shared utilities/hooks
import { useDebounce } from '@/shared/hooks';
import { isApiError } from '@/shared/api';

// Feature imports (cross-feature)
import { useSitesQuery } from '@/features/sites';

// Local feature imports (relative)
import { SiteCard } from '../components/SiteCard';
import type { Site } from '../types';
```

---

## 11. Decision Checklist

Before adding new files or folders, verify:

- [ ] File is placed in the correct feature module
- [ ] Naming follows conventions (Section 9)
- [ ] Component uses MUI (no custom UI without WP-012 approval)
- [ ] Shared code goes in `app/shared/`, not duplicated in features
- [ ] Types are defined in feature's `types.ts`, not inline
- [ ] Translations added to both `pt-AO` and `en-US` message files
- [ ] Route pages are thin — business logic in feature modules

---

## 12. Migration Notes

When implementing this structure:

1. **Start with `app/theme/`** — Theme must exist before components
2. **Then `app/shared/`** — Shared UI and utilities
3. **Then `i18n/`** — Internationalization setup
4. **Then features** — One feature at a time, starting with `auth`
5. **Then routes** — Connect route pages to feature components

See the implementation roadmap in `docs/pm/web_portal/` for phased delivery.
