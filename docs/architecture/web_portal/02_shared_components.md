# Jila Web Portal — Shared Components Catalog (v1)

> **Status**: DECIDED  
> **Last updated**: 2026-01-14  
> **Decision references**: WP-012, WP-013  
> **Related docs**:
> - Folder structure: `./01_folder_structure.md`
> - Layout spec: `../../design/03_web_layout_spec.md`
> - Component patterns: `../../design/02_component_patterns_spec.md`
> - Decision register: `../../decision_registers/web_portal_decision_register.md`

---

## 1. Overview

This document catalogs all **shared components** that should be implemented in `app/shared/` to ensure consistency and prevent duplicate implementations across features.

### Purpose

1. **Prevent duplication**: Single source of truth for common UI patterns
2. **Ensure consistency**: Same component = same behavior everywhere
3. **Enable discovery**: Developers can find existing components before creating new ones
4. **Reduce technical debt**: Clear naming prevents "similar but different" components

### Component Categories

| Category | Location | Purpose |
|----------|----------|---------|
| Status & Badges | `shared/ui/badges/` | Status indicators, severity levels, roles |
| Data Display | `shared/ui/data-display/` | Timestamps, percentages, counts |
| Identity | `shared/ui/identity/` | Avatars, profiles |
| Layout | `shared/ui/layout/` | Shell, containers, headers |
| State | `shared/ui/state/` | Empty, loading, error states |
| Lists & Cards | `shared/ui/lists/` | Pagination, entity cards |
| Form | `shared/form/` | Form field wrappers |

---

## 2. Status & Badge Components

Location: `app/shared/ui/badges/`

These components display status information with consistent styling per UX-P-005 (color is never the only signal).

### 2.1 StatusBadge

Generic status badge for entities with status enums.

```typescript
// shared/ui/badges/StatusBadge.tsx

interface StatusBadgeProps {
  status: string;
  variant: 'user' | 'order' | 'invite' | 'device' | 'supplyPoint';
  size?: 'small' | 'medium';
}

// Usage
<StatusBadge status="ACTIVE" variant="user" />
<StatusBadge status="PENDING_VERIFICATION" variant="user" />
<StatusBadge status="DELIVERED" variant="order" />
```

**Status Mappings:**

| Variant | Statuses | Colors |
|---------|----------|--------|
| `user` | ACTIVE, PENDING_VERIFICATION, LOCKED, DISABLED | success, info, warning, error |
| `order` | CREATED, ACCEPTED, REJECTED, CANCELLED, DELIVERED, DISPUTED | info, success, error, default, success, warning |
| `invite` | PENDING, EXPIRED, ACCEPTED | info, default, success |
| `device` | ONLINE, OFFLINE, MAINTENANCE | success, error, warning |
| `supplyPoint` | VERIFIED, PENDING_REVIEW, REJECTED, DECOMMISSIONED | success, info, error, default |

### 2.2 SeverityBadge

For alerts and risk indicators.

```typescript
// shared/ui/badges/SeverityBadge.tsx

interface SeverityBadgeProps {
  severity: 'critical' | 'warning' | 'info';
  showIcon?: boolean;
  size?: 'small' | 'medium';
}

// Usage
<SeverityBadge severity="critical" />
<SeverityBadge severity="warning" showIcon />
```

**Styling:**

| Severity | Color | Icon |
|----------|-------|------|
| `critical` | `palette.critical.main` (#DC2626) | `error` |
| `warning` | `palette.warning.main` (#D87C4A) | `warning` |
| `info` | `palette.info.main` (#248CFF) | `info` |

### 2.3 RiskLevelBadge

For site/reservoir risk levels.

```typescript
// shared/ui/badges/RiskLevelBadge.tsx

interface RiskLevelBadgeProps {
  level: 'critical' | 'warning' | 'stale' | 'good';
  showLabel?: boolean;
  size?: 'small' | 'medium';
}

// Usage
<RiskLevelBadge level="critical" />
<RiskLevelBadge level="good" showLabel />
```

**Styling:**

| Level | Color | Icon | Label |
|-------|-------|------|-------|
| `critical` | `critical.main` | `error` | "Critical" |
| `warning` | `warning.main` | `warning` | "Warning" |
| `stale` | `text.secondary` | `schedule` | "Stale" |
| `good` | `success.main` | `check_circle` | "Good" |

### 2.4 LevelStateBadge

For reservoir water level states.

```typescript
// shared/ui/badges/LevelStateBadge.tsx

interface LevelStateBadgeProps {
  state: 'full' | 'normal' | 'low' | 'critical';
  showIcon?: boolean;
  size?: 'small' | 'medium';
}

// Usage
<LevelStateBadge state="low" />
<LevelStateBadge state="critical" showIcon />
```

### 2.5 ConnectivityBadge

For device/reservoir connectivity state.

```typescript
// shared/ui/badges/ConnectivityBadge.tsx

interface ConnectivityBadgeProps {
  state: 'online' | 'offline' | 'stale';
  showLabel?: boolean;
  size?: 'small' | 'medium';
}

// Usage
<ConnectivityBadge state="online" />
<ConnectivityBadge state="offline" showLabel />
```

### 2.6 RoleBadge

For user roles in organization.

```typescript
// shared/ui/badges/RoleBadge.tsx

interface RoleBadgeProps {
  role: 'owner' | 'manager' | 'viewer';
  size?: 'small' | 'medium';
}

// Usage
<RoleBadge role="owner" />
<RoleBadge role="viewer" />
```

**Styling:**

| Role | Color | Icon |
|------|-------|------|
| `owner` | `secondary.main` | `admin_panel_settings` |
| `manager` | `primary.main` | `manage_accounts` |
| `viewer` | `text.secondary` | `visibility` |

### 2.7 Barrel Export

```typescript
// shared/ui/badges/index.ts
export { StatusBadge } from './StatusBadge';
export { SeverityBadge } from './SeverityBadge';
export { RiskLevelBadge } from './RiskLevelBadge';
export { LevelStateBadge } from './LevelStateBadge';
export { ConnectivityBadge } from './ConnectivityBadge';
export { RoleBadge } from './RoleBadge';

export type { StatusBadgeProps } from './StatusBadge';
export type { SeverityBadgeProps } from './SeverityBadge';
// ... etc
```

---

## 3. Data Display Components

Location: `app/shared/ui/data-display/`

Components for displaying common data patterns.

### 3.1 TimestampDisplay

Displays timestamps in relative or absolute format.

```typescript
// shared/ui/data-display/TimestampDisplay.tsx

interface TimestampDisplayProps {
  timestamp: string; // ISO8601
  format?: 'relative' | 'absolute' | 'both';
  showIcon?: boolean;
  staleThreshold?: number; // minutes after which to show stale styling
}

// Usage
<TimestampDisplay timestamp="2026-01-14T10:30:00Z" />
<TimestampDisplay timestamp={lastSeen} format="relative" />
<TimestampDisplay timestamp={createdAt} format="both" />
```

**Output Examples:**
- Relative: "5 minutes ago", "2 hours ago", "Yesterday"
- Absolute: "14 Jan 2026, 10:30"
- Both: "5 minutes ago (14 Jan 2026, 10:30)"

### 3.2 FreshnessIndicator

Shows data freshness with stale warnings.

```typescript
// shared/ui/data-display/FreshnessIndicator.tsx

interface FreshnessIndicatorProps {
  lastUpdated: string; // ISO8601
  staleThresholdMinutes?: number; // default: 30
  criticalThresholdMinutes?: number; // default: 60
  showTimestamp?: boolean;
}

// Usage
<FreshnessIndicator lastUpdated={reading.recorded_at} />
<FreshnessIndicator 
  lastUpdated={device.last_seen_at} 
  staleThresholdMinutes={15}
  showTimestamp 
/>
```

**States:**
- Fresh (< stale threshold): Green text, no warning
- Stale (stale < x < critical): Yellow warning icon + "Data may be stale"
- Critical (> critical threshold): Red warning icon + "Data is outdated"

### 3.3 PercentageIndicator

Displays percentage values with visual indicator.

```typescript
// shared/ui/data-display/PercentageIndicator.tsx

interface PercentageIndicatorProps {
  value: number; // 0-100
  variant: 'level' | 'battery';
  size?: 'small' | 'medium' | 'large';
  showLabel?: boolean;
  thresholds?: {
    low: number;
    critical: number;
  };
}

// Usage
<PercentageIndicator value={75} variant="level" />
<PercentageIndicator value={23} variant="battery" showLabel />
<PercentageIndicator 
  value={15} 
  variant="level" 
  thresholds={{ low: 30, critical: 15 }} 
/>
```

**Default Thresholds:**
- Level: low=30, critical=15
- Battery: low=20, critical=10

**Visual:**
- Uses LinearProgress or circular gauge
- Color changes based on thresholds (green → yellow → red)

### 3.4 CountBadge

Displays count with optional label and alert styling.

```typescript
// shared/ui/data-display/CountBadge.tsx

interface CountBadgeProps {
  count: number;
  label?: string;
  variant?: 'default' | 'alert';
  icon?: ReactNode;
}

// Usage
<CountBadge count={5} label="reservoirs" />
<CountBadge count={3} label="alerts" variant="alert" />
<CountBadge count={12} icon={<DevicesIcon />} />
```

### 3.5 KpiValue

Large-format KPI display for dashboards.

```typescript
// shared/ui/data-display/KpiValue.tsx

interface KpiValueProps {
  value: number | string;
  label: string;
  trend?: {
    direction: 'up' | 'down' | 'stable';
    value: string; // e.g., "+12%", "-3"
  };
  icon?: ReactNode;
  onClick?: () => void;
}

// Usage
<KpiValue value={48} label="Total Reservoirs" />
<KpiValue 
  value={5} 
  label="Active Alerts" 
  trend={{ direction: 'up', value: '+2' }}
  onClick={() => navigate('/alerts')}
/>
```

### 3.6 Barrel Export

```typescript
// shared/ui/data-display/index.ts
export { TimestampDisplay } from './TimestampDisplay';
export { FreshnessIndicator } from './FreshnessIndicator';
export { PercentageIndicator } from './PercentageIndicator';
export { CountBadge } from './CountBadge';
export { KpiValue } from './KpiValue';
```

---

## 4. Identity Components

Location: `app/shared/ui/identity/`

Components for displaying user/profile information.

### 4.1 ProfileAvatar

Displays user avatar with fallback to initials.

```typescript
// shared/ui/identity/ProfileAvatar.tsx

interface ProfileAvatarProps {
  displayName?: string | null;
  avatarUri?: string | null;
  size?: 'xs' | 'sm' | 'md' | 'lg' | 'xl';
  showTooltip?: boolean;
}

// Size mapping
const sizes = {
  xs: 24,
  sm: 32,
  md: 40,
  lg: 48,
  xl: 64,
};

// Usage
<ProfileAvatar displayName="João Silva" />
<ProfileAvatar displayName="Maria" avatarUri="/api/v1/avatars/abc" size="lg" />
<ProfileAvatar displayName={null} /> // Shows default person icon
```

**Behavior:**
- If `avatarUri` provided: Show image
- If only `displayName`: Show initials (first letter of first two words)
- If neither: Show generic person icon

### 4.2 UserInfo

Displays user name with optional role and email.

```typescript
// shared/ui/identity/UserInfo.tsx

interface UserInfoProps {
  displayName: string;
  email?: string;
  role?: 'owner' | 'manager' | 'viewer';
  avatarUri?: string;
  size?: 'compact' | 'default' | 'expanded';
}

// Usage
<UserInfo displayName="João Silva" email="joao@example.com" role="manager" />
<UserInfo displayName="Maria Santos" size="compact" />
```

### 4.3 Barrel Export

```typescript
// shared/ui/identity/index.ts
export { ProfileAvatar } from './ProfileAvatar';
export { UserInfo } from './UserInfo';
```

---

## 5. Layout Components

Location: `app/shared/ui/layout/`

Components for page structure and layout.

### 5.1 PortalShell

Main layout wrapper for all portal pages.

```typescript
// shared/ui/layout/PortalShell.tsx

interface PortalShellProps {
  children: ReactNode;
}

// Usage (in app/[locale]/(portal)/layout.tsx)
export default function PortalLayout({ children }) {
  return <PortalShell>{children}</PortalShell>;
}
```

**Composition:**
- Manages sidebar state (expanded/collapsed)
- Renders Topbar and Sidebar
- Wraps children in ContentContainer

### 5.2 Sidebar

Navigation sidebar with collapsible state.

```typescript
// shared/ui/layout/Sidebar.tsx

interface NavItem {
  label: string;
  icon: ReactNode;
  href: string;
  badge?: number;
  children?: NavItem[];
}

interface SidebarProps {
  items: NavItem[];
  collapsed?: boolean;
  onToggle?: () => void;
}

// Usage (internal to PortalShell)
<Sidebar items={navItems} collapsed={isCollapsed} onToggle={toggleSidebar} />
```

### 5.3 Topbar

Application header with breadcrumbs and user menu.

```typescript
// shared/ui/layout/Topbar.tsx

interface TopbarProps {
  onMenuClick?: () => void; // Mobile hamburger
  showSearch?: boolean;
}

// Usage (internal to PortalShell)
<Topbar onMenuClick={openMobileMenu} showSearch />
```

### 5.4 ContentContainer

Max-width wrapper with responsive padding.

```typescript
// shared/ui/layout/ContentContainer.tsx

interface ContentContainerProps {
  children: ReactNode;
  maxWidth?: 'sm' | 'md' | 'lg' | 'xl' | 'full';
  disablePadding?: boolean;
}

// Max-width mapping
const maxWidths = {
  sm: 600,
  md: 900,
  lg: 1280, // default
  xl: 1536,
  full: '100%',
};

// Usage
<ContentContainer>{children}</ContentContainer>
<ContentContainer maxWidth="md">{/* Form content */}</ContentContainer>
```

### 5.5 PageHeader

Consistent page header with title, subtitle, breadcrumbs, and actions.

```typescript
// shared/ui/layout/PageHeader.tsx

interface Breadcrumb {
  label: string;
  href?: string;
}

interface PageHeaderProps {
  title: string;
  subtitle?: string;
  breadcrumbs?: Breadcrumb[];
  actions?: ReactNode;
}

// Usage
<PageHeader title="Sites" actions={<Button>Add Site</Button>} />
<PageHeader 
  title="Water Plant Alpha" 
  subtitle="Site details"
  breadcrumbs={[
    { label: 'Sites', href: '/sites' },
    { label: 'Water Plant Alpha' },
  ]}
  actions={
    <>
      <Button variant="outlined">Edit</Button>
      <Button color="error">Delete</Button>
    </>
  }
/>
```

### 5.6 ListToolbar

Toolbar for list pages with search, filters, and primary action.

```typescript
// shared/ui/layout/ListToolbar.tsx

interface FilterOption {
  label: string;
  value: string;
}

interface ListToolbarProps {
  searchPlaceholder?: string;
  searchValue?: string;
  onSearchChange?: (value: string) => void;
  filters?: {
    label: string;
    options: FilterOption[];
    value: string;
    onChange: (value: string) => void;
  }[];
  primaryAction?: {
    label: string;
    onClick: () => void;
    icon?: ReactNode;
  };
}

// Usage
<ListToolbar
  searchPlaceholder="Search sites..."
  searchValue={search}
  onSearchChange={setSearch}
  filters={[
    {
      label: 'Risk Level',
      options: [
        { label: 'All', value: 'all' },
        { label: 'Critical', value: 'critical' },
        { label: 'Warning', value: 'warning' },
      ],
      value: riskFilter,
      onChange: setRiskFilter,
    },
  ]}
  primaryAction={{
    label: 'Add Site',
    onClick: () => navigate('/sites/new'),
    icon: <AddIcon />,
  }}
/>
```

### 5.7 Barrel Export

```typescript
// shared/ui/layout/index.ts
export { PortalShell } from './PortalShell';
export { Sidebar } from './Sidebar';
export { Topbar } from './Topbar';
export { ContentContainer } from './ContentContainer';
export { PageHeader } from './PageHeader';
export { ListToolbar } from './ListToolbar';
```

---

## 6. State Components

Location: `app/shared/ui/state/`

Components for loading, empty, and error states per UX-D-049.

### 6.1 EmptyState

Empty state display with illustration, message, and action.

```typescript
// shared/ui/state/EmptyState.tsx

interface EmptyStateProps {
  icon?: ReactNode;
  title: string;
  description?: string;
  action?: {
    label: string;
    onClick: () => void;
    icon?: ReactNode;
  };
}

// Usage
<EmptyState
  icon={<SitesIcon />}
  title="No sites yet"
  description="Create your first site to start monitoring"
  action={{
    label: 'Add Site',
    onClick: () => navigate('/sites/new'),
  }}
/>
```

### 6.2 LoadingSkeleton

Skeleton placeholders for loading states.

```typescript
// shared/ui/state/LoadingSkeleton.tsx

interface LoadingSkeletonProps {
  variant: 'card' | 'list-item' | 'table-row' | 'detail' | 'kpi';
  count?: number;
}

// Usage
<LoadingSkeleton variant="card" count={4} />
<LoadingSkeleton variant="table-row" count={10} />
<LoadingSkeleton variant="detail" />
```

**Variants:**
- `card`: Card-shaped skeleton (matches EntityCard)
- `list-item`: Single row skeleton
- `table-row`: Table row with columns
- `detail`: Detail page layout skeleton
- `kpi`: KPI card skeleton

### 6.3 ErrorDisplay

Error message with retry action.

```typescript
// shared/ui/state/ErrorDisplay.tsx

interface ErrorDisplayProps {
  error: Error | { message: string; error_code?: string };
  onRetry?: () => void;
  variant?: 'inline' | 'full-page';
}

// Usage
<ErrorDisplay error={error} onRetry={refetch} />
<ErrorDisplay error={error} variant="full-page" />
```

**Display:**
- Shows error icon + message
- Maps known `error_code` values to user-friendly messages
- Shows "Retry" button if `onRetry` provided
- `full-page` variant centers content vertically

### 6.4 LoadingOverlay

Overlay for in-progress mutations.

```typescript
// shared/ui/state/LoadingOverlay.tsx

interface LoadingOverlayProps {
  isLoading: boolean;
  message?: string;
}

// Usage
<LoadingOverlay isLoading={isSubmitting} message="Saving..." />
```

### 6.5 Barrel Export

```typescript
// shared/ui/state/index.ts
export { EmptyState } from './EmptyState';
export { LoadingSkeleton } from './LoadingSkeleton';
export { ErrorDisplay } from './ErrorDisplay';
export { LoadingOverlay } from './LoadingOverlay';
```

---

## 7. List & Card Components

Location: `app/shared/ui/lists/`

Components for displaying collections of entities.

### 7.1 PaginatedList

Generic paginated list with cursor-based pagination.

```typescript
// shared/ui/lists/PaginatedList.tsx

interface PaginatedListProps<T> {
  items: T[];
  renderItem: (item: T) => ReactNode;
  keyExtractor: (item: T) => string;
  isLoading?: boolean;
  hasNextPage?: boolean;
  onLoadMore?: () => void;
  emptyState?: ReactNode;
  loadingState?: ReactNode;
  gridColumns?: { xs?: number; sm?: number; md?: number; lg?: number };
}

// Usage
<PaginatedList
  items={sites}
  renderItem={(site) => <SiteCard site={site} />}
  keyExtractor={(site) => site.site_id}
  isLoading={isLoading}
  hasNextPage={!!nextCursor}
  onLoadMore={fetchNextPage}
  emptyState={<EmptyState title="No sites" />}
  gridColumns={{ xs: 1, sm: 2, md: 3, lg: 4 }}
/>
```

### 7.2 EntityCard

Base card component for entity displays.

```typescript
// shared/ui/lists/EntityCard.tsx

interface EntityCardProps {
  header: ReactNode;
  content: ReactNode;
  footer?: ReactNode;
  onClick?: () => void;
  selected?: boolean;
  disabled?: boolean;
  actions?: ReactNode; // Appears in card menu
}

// Usage
<EntityCard
  header={
    <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
      <Typography variant="h6">Water Plant Alpha</Typography>
      <RiskLevelBadge level="good" />
    </Box>
  }
  content={
    <Stack spacing={1}>
      <Typography variant="body2">Luanda, Angola</Typography>
      <Box sx={{ display: 'flex', gap: 2 }}>
        <CountBadge count={5} label="reservoirs" />
        <CountBadge count={3} label="devices" />
      </Box>
    </Stack>
  }
  footer={
    <TimestampDisplay timestamp={site.updated_at} format="relative" />
  }
  onClick={() => navigate(`/sites/${site.site_id}`)}
/>
```

### 7.3 DataTable

Wrapper around MUI DataGrid with project defaults.

```typescript
// shared/ui/lists/DataTable.tsx

interface DataTableProps<T> {
  rows: T[];
  columns: GridColDef[];
  loading?: boolean;
  onRowClick?: (row: T) => void;
  pagination?: {
    page: number;
    pageSize: number;
    onPageChange: (page: number) => void;
    onPageSizeChange: (size: number) => void;
    rowCount: number;
  };
  emptyState?: ReactNode;
}

// Usage
<DataTable
  rows={devices}
  columns={deviceColumns}
  loading={isLoading}
  onRowClick={(device) => navigate(`/devices/${device.device_id}`)}
  emptyState={<EmptyState title="No devices" />}
/>
```

### 7.4 Barrel Export

```typescript
// shared/ui/lists/index.ts
export { PaginatedList } from './PaginatedList';
export { EntityCard } from './EntityCard';
export { DataTable } from './DataTable';
```

---

## 8. Form Components

Location: `app/shared/form/`

Form field wrappers integrating React Hook Form with MUI.

### 8.1 FormTextField

Text field integrated with React Hook Form.

```typescript
// shared/form/FormTextField.tsx

interface FormTextFieldProps {
  name: string;
  label: string;
  placeholder?: string;
  type?: 'text' | 'email' | 'password' | 'number';
  multiline?: boolean;
  rows?: number;
  required?: boolean;
  disabled?: boolean;
  helperText?: string;
}

// Usage (inside FormProvider)
<FormTextField name="name" label="Site Name" required />
<FormTextField name="description" label="Description" multiline rows={3} />
```

### 8.2 FormSelect

Select field integrated with React Hook Form.

```typescript
// shared/form/FormSelect.tsx

interface FormSelectProps {
  name: string;
  label: string;
  options: { value: string; label: string }[];
  required?: boolean;
  disabled?: boolean;
  multiple?: boolean;
}

// Usage
<FormSelect
  name="site_type"
  label="Site Type"
  options={[
    { value: 'RESIDENTIAL', label: 'Residential' },
    { value: 'COMMERCIAL', label: 'Commercial' },
    { value: 'INDUSTRIAL', label: 'Industrial' },
  ]}
  required
/>
```

### 8.3 FormDatePicker

Date picker integrated with React Hook Form.

```typescript
// shared/form/FormDatePicker.tsx

interface FormDatePickerProps {
  name: string;
  label: string;
  minDate?: Date;
  maxDate?: Date;
  required?: boolean;
  disabled?: boolean;
}

// Usage
<FormDatePicker name="start_date" label="Start Date" minDate={new Date()} />
```

### 8.4 FormSwitch

Switch/toggle integrated with React Hook Form.

```typescript
// shared/form/FormSwitch.tsx

interface FormSwitchProps {
  name: string;
  label: string;
  helperText?: string;
  disabled?: boolean;
}

// Usage
<FormSwitch name="notifications_enabled" label="Enable Notifications" />
```

### 8.5 FormError

Form-level error display.

```typescript
// shared/form/FormError.tsx

interface FormErrorProps {
  error?: string | null;
}

// Usage
<FormError error={submitError?.message} />
```

### 8.6 Barrel Export

```typescript
// shared/form/index.ts
export { FormTextField } from './FormTextField';
export { FormSelect } from './FormSelect';
export { FormDatePicker } from './FormDatePicker';
export { FormSwitch } from './FormSwitch';
export { FormError } from './FormError';
```

---

## 9. Main Barrel Export

```typescript
// shared/ui/index.ts

// Badges
export * from './badges';

// Data Display
export * from './data-display';

// Identity
export * from './identity';

// Layout
export * from './layout';

// State
export * from './state';

// Lists
export * from './lists';
```

```typescript
// shared/index.ts
export * from './ui';
export * from './form';
export * from './hooks';
export * from './lib';
export * from './api';
```

---

## 10. Usage Guidelines

### 10.1 Import Pattern

```typescript
// Preferred: Import from category barrel
import { StatusBadge, RiskLevelBadge } from '@/shared/ui/badges';
import { PageHeader, ContentContainer } from '@/shared/ui/layout';
import { EmptyState, LoadingSkeleton } from '@/shared/ui/state';

// Also valid: Import from main barrel
import { StatusBadge, PageHeader, EmptyState } from '@/shared/ui';

// For forms
import { FormTextField, FormSelect } from '@/shared/form';
```

### 10.2 When to Add New Shared Components

Add to `shared/` when:
- Component is used by **2+ features**
- Component implements a **design system pattern** (from `02_component_patterns_spec.md`)
- Component represents a **common data display** pattern (timestamps, statuses, etc.)

Keep in feature when:
- Component is **feature-specific** (e.g., `ReservoirLevelChart`)
- Component has **no reuse potential** across features
- Component is a **composition** of shared components for a specific use case

### 10.3 Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Badge components | `*Badge` | `StatusBadge`, `RoleBadge` |
| Display components | Descriptive noun | `TimestampDisplay`, `PercentageIndicator` |
| Layout components | Layout role | `PageHeader`, `ContentContainer` |
| State components | State name | `EmptyState`, `LoadingSkeleton` |
| Form components | `Form*` | `FormTextField`, `FormSelect` |

### 10.4 Modification Policy

Per WP-012, modifications to shared components that **add new behavior** require decision register approval. Modifications that **fix bugs** or **improve existing behavior** do not require approval but should be documented in PR descriptions.

---

## 11. Component Checklist

### Implementation Priority

**Phase 1 (Required for first screens):**
- [ ] `PortalShell`, `Sidebar`, `Topbar`
- [ ] `ContentContainer`, `PageHeader`
- [ ] `EmptyState`, `LoadingSkeleton`, `ErrorDisplay`
- [ ] `StatusBadge`, `RiskLevelBadge`
- [ ] `TimestampDisplay`
- [ ] `EntityCard`, `PaginatedList`

**Phase 2 (Required for feature completion):**
- [ ] `ListToolbar`
- [ ] `SeverityBadge`, `ConnectivityBadge`, `LevelStateBadge`, `RoleBadge`
- [ ] `FreshnessIndicator`, `PercentageIndicator`, `CountBadge`
- [ ] `ProfileAvatar`, `UserInfo`
- [ ] `KpiValue`
- [ ] `DataTable`

**Phase 3 (Forms):**
- [ ] `FormTextField`, `FormSelect`, `FormDatePicker`, `FormSwitch`, `FormError`
- [ ] `LoadingOverlay`

---

## 12. References

- Component patterns: `../../design/02_component_patterns_spec.md`
- Layout spec: `../../design/03_web_layout_spec.md`
- Decision register: `../../decision_registers/web_portal_decision_register.md`
- MUI Components: https://mui.com/material-ui/
