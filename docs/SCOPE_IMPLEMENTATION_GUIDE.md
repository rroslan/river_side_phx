# Scope Implementation Guide for River Side Food Court

## Overview

This document outlines the comprehensive changes made to implement a scope-based authorization system throughout the River Side Food Court application. The scope system provides role-based access control, permission management, and context-aware authorization for different user types (admin, vendor, cashier, customer, and guest).

## Table of Contents

1. [Previous Setup vs New Setup](#previous-setup-vs-new-setup)
2. [Key Components Added](#key-components-added)
3. [Modified Files](#modified-files)
4. [Implementation Details](#implementation-details)
5. [Migration Steps](#migration-steps)
6. [Testing the Implementation](#testing-the-implementation)

## Previous Setup vs New Setup

### Previous Setup
- Direct user authentication without role context
- Basic role checks using boolean fields (is_admin, is_vendor, is_cashier)
- No centralized permission management
- Limited context awareness (e.g., vendor data not preloaded)
- Simple authentication flow without role-based redirects

### New Setup
- Comprehensive scope system with role-based contexts
- Centralized permission management
- Resource-based authorization
- Preloaded context data (vendor information for vendor users)
- Smart redirects based on user roles
- Customer session management without authentication

## Key Components Added

### 1. Scope Module (`lib/river_side/accounts/scope.ex`)

**Purpose**: Central module for managing user contexts and permissions

**Key Features**:
- Role determination based on user attributes
- Permission maps for each role
- Context loading (vendor data for vendor users)
- Customer session management
- Helper functions for permission checks

```elixir
defstruct [
  :user,
  :role,           # :admin, :vendor, :cashier, :customer, :guest
  :vendor,         # Preloaded vendor for vendor users
  :permissions,    # Map of allowed actions
  :customer_info,  # For customer sessions
  :session_id,
  :expires_at
]
```

### 2. Authorization Module (`lib/river_side/authorization.ex`)

**Purpose**: Resource-based access control

**Key Features**:
- Policy-based authorization
- Resource ownership checks
- Action-based permissions
- Extensible policy system

### 3. Enhanced UserAuth Module

**Major Changes**:
- Added `fetch_current_scope_for_user/2` to create scopes from sessions
- Modified `log_in_user/3` to handle role-based redirects
- Added role-specific mount callbacks
- Fixed scope creation during authentication

## Modified Files

### 1. `lib/river_side_web/user_auth.ex`

**Key Changes**:
```elixir
# Added scope creation during login
def log_in_user(conn, user, params \\ %{}) do
  user_return_to = get_session(conn, :user_return_to)
  scope = Scope.for_user(user)
  
  conn
  |> create_or_extend_session(user, params)
  |> assign(:current_scope, scope)
  |> redirect(to: user_return_to || signed_in_path_for_scope(scope))
end

# Added helper for role-based redirects
defp signed_in_path_for_scope(%Scope{role: :admin}), do: ~p"/admin/dashboard"
defp signed_in_path_for_scope(%Scope{role: :vendor}), do: ~p"/vendor/dashboard"
defp signed_in_path_for_scope(%Scope{role: :cashier}), do: ~p"/cashier/dashboard"
```

### 2. `lib/river_side_web/router.ex`

**Key Changes**:
```elixir
# Admin routes with scope protection
live_session :admin,
  on_mount: [{RiverSideWeb.UserAuth, :require_admin_scope}] do
  live "/dashboard", AdminLive.Dashboard, :index
  live "/vendors", AdminLive.VendorList, :index
end

# Similar patterns for vendor and cashier routes
```

### 3. `lib/river_side_web/live/user_live/login.ex`

**Key Changes**:
- Fixed readonly attribute issue (was passing user struct instead of boolean)
- Added automatic redirect for already logged-in users
- Improved user experience by directing to appropriate dashboards

### 4. Dashboard Files

All dashboard files now properly utilize the scope system:
- Access vendor data through `@current_scope.vendor`
- Use scope for permission checks
- Rely on scope-based authentication

## Implementation Details

### Role Hierarchy and Permissions

#### Admin Permissions
```elixir
%{
  view_all_vendors: true,
  manage_vendors: true,
  view_all_orders: true,
  manage_orders: true,
  process_payments: true,
  view_all_transactions: true,
  access_admin_dashboard: true,
  access_vendor_dashboard: true,
  access_cashier_dashboard: true
}
```

#### Vendor Permissions
```elixir
%{
  view_own_menu: true,
  manage_menu: true,
  view_own_orders: true,
  manage_orders: true,
  view_own_analytics: true,
  access_vendor_dashboard: true
}
```

#### Cashier Permissions
```elixir
%{
  process_payments: true,
  mark_orders_paid: true,
  view_payment_queue: true,
  view_all_orders: true,
  access_cashier_dashboard: true
}
```

### Authentication Flow

1. User requests magic link
2. User clicks link with token
3. `UserSessionController` validates token
4. `UserAuth.log_in_user/3` creates scope and session
5. User redirected to role-appropriate dashboard
6. Subsequent requests load scope via `fetch_current_scope_for_user/2`

## Migration Steps

If you're implementing a similar scope system in an existing Phoenix application:

### Step 1: Create the Scope Module
```bash
# Create the scope module
touch lib/your_app/accounts/scope.ex
```

### Step 2: Add Authorization Module
```bash
# Create authorization module
touch lib/your_app/authorization.ex
```

### Step 3: Update UserAuth
1. Add `fetch_current_scope_for_user/2` plug
2. Modify `log_in_user/3` to create scope
3. Add role-specific on_mount callbacks
4. Update permission check functions

### Step 4: Update Router
1. Replace `require_authenticated_user` with role-specific plugs
2. Add live_session groups with appropriate on_mount callbacks
3. Group routes by role requirements

### Step 5: Update Controllers/LiveViews
1. Replace `@current_user` with `@current_scope`
2. Use scope for permission checks
3. Access role-specific data through scope

### Step 6: Fix Edge Cases
1. Handle readonly form fields properly
2. Add proper redirects for logged-in users
3. Ensure CSRF token handling works with new session flow

## Testing the Implementation

### Manual Testing Checklist

1. **Admin Access**
   - [ ] Login as admin user
   - [ ] Verify redirect to `/admin/dashboard`
   - [ ] Check access to vendor management
   - [ ] Verify cannot access when logged out

2. **Vendor Access**
   - [ ] Login as vendor user
   - [ ] Verify redirect to `/vendor/dashboard`
   - [ ] Check vendor data is preloaded
   - [ ] Verify cannot access admin routes

3. **Cashier Access**
   - [ ] Login as cashier user
   - [ ] Verify redirect to `/cashier/dashboard`
   - [ ] Check payment processing access
   - [ ] Verify cannot access vendor/admin routes

4. **Customer Flow**
   - [ ] Test customer check-in
   - [ ] Verify customer scope creation
   - [ ] Check session expiration

### Common Issues and Solutions

1. **Protocol.UndefinedError for Phoenix.HTML.Safe**
   - Cause: Passing structs to HTML attributes
   - Solution: Ensure boolean values for HTML attributes

2. **Redirect Loop to Login**
   - Cause: Scope not properly created during authentication
   - Solution: Create scope in `log_in_user/3` before redirect

3. **Cannot Access Dashboard**
   - Cause: Missing role-specific data (e.g., vendor record)
   - Solution: Handle missing data in mount functions

## Conclusion

The scope implementation provides a robust, maintainable authorization system that:
- Centralizes permission management
- Provides clear role separation
- Enables context-aware authorization
- Improves code organization
- Enhances security

This pattern can be adapted to other Phoenix applications requiring complex multi-role authorization systems.