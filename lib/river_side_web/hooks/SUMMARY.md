# River Side Web Hooks Summary

## Overview

This directory contains LiveView hooks for the River Side Food Court application. The main hook is `RequireRole`, which provides flexible role-based access control that integrates with the existing Scope-based authorization system.

## Why Not Use the Original Hook?

The original hook you provided:

```elixir
defmodule RiverSidePhxWeb.Hooks.RequireRole do
  import Phoenix.LiveView
  def on_mount(:admin, _params, _session, socket) do
    if socket.assigns.current_user.is_admin do
      {:cont, socket}
    else
      {:halt, socket |> Phoenix.LiveView.redirect(to: "/unauthorized")}
    end
  end
end
```

Would not work in this codebase because:

1. **No `current_user` in assigns** - The River Side app uses `current_scope` instead
2. **Scope-based authorization** - The app uses a sophisticated Scope pattern that encapsulates user, role, permissions, and context
3. **Missing error handling** - No handling for unauthenticated users or proper error messages
4. **Incorrect redirect** - The `/unauthorized` route doesn't exist in the router

## The Correct Implementation

The `RequireRole` hook in this directory:

1. **Works with the Scope system** - Checks `socket.assigns.current_scope` and the role within it
2. **Provides comprehensive role support** - Handles admin, vendor, cashier, customer, and authenticated users
3. **Includes permission-based checks** - Can check specific permissions, not just roles
4. **Proper error handling** - Redirects to appropriate dashboards with informative error messages
5. **Validates business rules** - E.g., ensures vendors have associated vendor records

## Usage Examples

### Basic Role Requirement

```elixir
# In router.ex
live_session :admin_pages,
  on_mount: [{RiverSideWeb.Hooks.RequireRole, :admin}] do
  live "/admin/users", AdminLive.Users, :index
end
```

### Multiple Roles

```elixir
live_session :staff_area,
  on_mount: [{RiverSideWeb.Hooks.RequireRole, {:any, [:admin, :cashier]}}] do
  live "/staff/reports", StaffLive.Reports, :index
end
```

### Permission-Based

```elixir
live_session :financial,
  on_mount: [{RiverSideWeb.Hooks.RequireRole, {:permission, :process_payments}}] do
  live "/payments/process", PaymentLive.Process, :new
end
```

## Available Hooks

- `:admin` - Requires admin role
- `:vendor` - Requires vendor role with valid vendor record
- `:cashier` - Requires cashier role
- `:customer` - Requires active customer session
- `:authenticated` - Requires any authenticated user (not customers)
- `{:permission, atom}` - Requires specific permission
- `{:any, [roles]}` - Requires any of the listed roles

## Integration with Existing System

The hook integrates seamlessly with:

1. **UserAuth module** - Can be used alongside existing UserAuth hooks
2. **Scope system** - Leverages the centralized role and permission system
3. **Router patterns** - Follows the existing live_session patterns
4. **Error handling** - Uses the same redirect and flash message patterns

## Files in This Directory

1. **require_role.ex** - The main hook implementation
2. **example_comparison.ex** - Shows the differences between the original and correct implementations
3. **README.md** - Comprehensive documentation with examples
4. **SUMMARY.md** - This file, providing a quick overview

## Best Practices

1. Use the most specific role requirement possible
2. Consider permissions over roles for cross-role features
3. Always include proper error messages
4. Test authorization thoroughly
5. Document why specific roles are required

## Migration Path

If you're currently using UserAuth hooks, you can gradually migrate:

```elixir
# Old way
on_mount: [{RiverSideWeb.UserAuth, :require_admin_scope}]

# New way (equivalent)
on_mount: [{RiverSideWeb.Hooks.RequireRole, :admin}]

# Or use both during transition
on_mount: [
  {RiverSideWeb.UserAuth, :mount_current_scope},
  {RiverSideWeb.Hooks.RequireRole, :admin}
]
```

The RequireRole hook provides more flexibility and cleaner syntax while maintaining full compatibility with the existing authorization system.