# Mock Data Screens (Baseline)

This is a **baseline snapshot** of routed screens that still rely on mock data (directly or indirectly).

Update this file as part of incremental migration from mock → real API data.

## Routed screens still using mock data

| Route | Screen | File | Mock source(s) | Status |
| --- | --- | --- | --- | --- |
| `/dashboard` | `DashboardPage` | `src/features/dashboard/pages/DashboardPage.tsx` | Dashboard widgets use hardcoded `mockAlerts` + `mockPriorityItems` (via components) | mock-only |
| `/devices` | `DevicesListPage` | `src/features/devices/pages/DevicesListPage.tsx` | Uses mock-derived stats; devices feature API is mock-only in real mode | mock-only |
| `/devices/new` | `DeviceConnectPage` | `src/features/devices/pages/DeviceConnectPage.tsx` | Inline `MOCK_SITES` + simulated validation/connect (TODO API) | mock-only |
| `/devices/$deviceId` | `DeviceDetailPage` | `src/features/devices/pages/DeviceDetailPage.tsx` | Devices feature API is mock-only in real mode | mock-only |
| `/devices/$deviceId/edit` | `DeviceEditPage` | `src/features/devices/pages/DeviceEditPage.tsx` | Update flow is stubbed (TODO API); devices feature API is mock-only in real mode | mock-only |
| `/users` | `MembersListPage` | `src/features/usersAccess/pages/MembersListPage.tsx` | Uses mock helpers + usersAccess feature API is mock-only in real mode | mock-only |
| `/users/invites` | `InvitesManagementPage` | `src/features/usersAccess/pages/InvitesManagementPage.tsx` | Uses mock helpers + usersAccess feature API is mock-only in real mode | mock-only |
| `/users/$userId/scope` | `ScopeSelectionPage` | `src/features/usersAccess/pages/ScopeSelectionPage.tsx` | Uses `mockScopeSites` (tree data) | mock-only |
| `/settings` | `SettingsPage` | `src/features/settings/pages/SettingsPage.tsx` | Settings tabs use `src/features/settings/data/mockSettings.ts` | mock-only |
| `/reservoirs/new/step-1` | `CreateReservoirStep1Page` | `src/features/reservoirs/pages/CreateReservoirStep1Page.tsx` | Uses `mockSites` for site selection | mock-only |
| `/reservoirs/new/step-2` | `CreateReservoirStep2Page` | `src/features/reservoirs/pages/CreateReservoirStep2Page.tsx` | Wizard flow depends on Step 1 mock site selection; create action not wired | mock-only |
| `/reservoirs/new/step-3` | `CreateReservoirStep3Page` | `src/features/reservoirs/pages/CreateReservoirStep3Page.tsx` | Uses `getSiteById` from `mockSites`; create action not wired | mock-only |
| `/invite/$inviteToken` | `InviteAcceptPage` | `src/features/auth/pages/InviteAcceptPage.tsx` | Inline `mockInviteData`; accept action is stubbed (TODO API) | mock-only |
| `/alerts` | `AlertsInboxPage` | `src/features/alerts/pages/AlertsInboxPage.tsx` | Alerts API supports mock mode; real mapping still TODO | hybrid |

## Hybrid screens (mock + real)

- **Reservoir list/detail routes** (`/reservoirs`, `/reservoirs/$reservoirId`): the `reservoirs` feature API supports both mock and real (mock branch remains for dev/testing).

## Global mock fallbacks (cross-cutting)

- `src/layout/Sidebar.tsx` falls back to `src/config/mockCurrentUser.ts` (`mockCurrentOrganization`) when org context isn’t available.

