# RequireRole Hook Documentation

The `RequireRole` hook provides a flexible way to enforce role-based access control in LiveView applications. It integrates seamlessly with the existing Scope-based authorization system.

## Basic Usage

### Single Role Requirements

You can require a specific role for accessing a LiveView:

```elixir
# In your router.ex
live_session :admin_only,
  on_mount: [{RiverSideWeb.Hooks.RequireRole, :admin}] do
  live "/admin/users", AdminLive.Users, :index
  live "/admin/settings", AdminLive.Settings, :edit
end

live_session :vendor_only,
  on_mount: [{RiverSideWeb.Hooks.RequireRole, :vendor}] do
  live "/vendor/analytics", VendorLive.Analytics, :index
  live "/vendor/inventory", VendorLive.Inventory, :index
end
```

### Multiple Roles

Allow access to users with any of the specified roles:

```elixir
live_session :staff_area,
  on_mount: [{RiverSideWeb.Hooks.RequireRole, {:any, [:admin, :cashier]}}] do
  live "/staff/reports", StaffLive.Reports, :index
  live "/staff/transactions", StaffLive.Transactions, :index
end
```

### Permission-Based Access

Check for specific permissions rather than roles:

```elixir
live_session :payment_processing,
  on_mount: [{RiverSideWeb.Hooks.RequireRole, {:permission, :process_payments}}] do
  live "/payments/process", PaymentLive.Process, :new
  live "/payments/refunds", PaymentLive.Refunds, :index
end
```

## Available Role Atoms

- `:admin` - System administrators
- `:vendor` - Vendor users (must have associated vendor record)
- `:cashier` - Cashier users
- `:customer` - Customer sessions (checked in with phone/table)
- `:authenticated` - Any authenticated user (excludes customers)

## Combining with Existing Hooks

You can combine the RequireRole hook with other on_mount callbacks:

```elixir
live_session :admin_with_logging,
  on_mount: [
    {RiverSideWeb.UserAuth, :mount_current_scope},
    {RiverSideWeb.Hooks.RequireRole, :admin},
    {RiverSideWeb.Hooks.ActivityLogger, :log_access}
  ] do
  live "/admin/audit", AdminLive.AuditLog, :index
end
```

## Migration from UserAuth Hooks

If you're currently using the UserAuth module's role-specific hooks, you can migrate to RequireRole:

```elixir
# Before (using UserAuth)
live_session :admin,
  on_mount: [{RiverSideWeb.UserAuth, :require_admin_scope}] do
  live "/admin/dashboard", AdminLive.Dashboard, :index
end

# After (using RequireRole)
live_session :admin,
  on_mount: [{RiverSideWeb.Hooks.RequireRole, :admin}] do
  live "/admin/dashboard", AdminLive.Dashboard, :index
end
```

## Error Handling

The hook automatically handles unauthorized access by:

1. Redirecting authenticated users to their appropriate dashboard
2. Redirecting unauthenticated users to the login page
3. Showing descriptive error messages
4. Handling expired customer sessions

## Special Cases

### Vendor Validation

The vendor role hook includes additional validation to ensure the vendor has an associated vendor record:

```elixir
# This will fail if user.is_vendor is true but no vendor record exists
on_mount: [{RiverSideWeb.Hooks.RequireRole, :vendor}]
```

### Customer Session Validation

The customer role hook validates that the session hasn't expired:

```elixir
# Customer sessions expire after 4 hours
on_mount: [{RiverSideWeb.Hooks.RequireRole, :customer}]
```

## Advanced Usage

### Custom Permission Checks in LiveView

While the hook handles initial access control, you can perform additional checks within your LiveView:

```elixir
defmodule MyAppWeb.VendorLive.Orders do
  use MyAppWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    # The hook ensures we have a vendor scope
    scope = socket.assigns.current_scope
    
    # Additional permission check
    if Scope.can?(scope, :view_own_orders) do
      {:ok, assign(socket, :orders, load_vendor_orders(scope.vendor))}
    else
      {:ok, 
       socket
       |> put_flash(:error, "You don't have permission to view orders")
       |> push_navigate(to: "/vendor/dashboard")}
    end
  end
end
```

### Dynamic Role Requirements

For more complex scenarios, you can create custom on_mount callbacks:

```elixir
defmodule MyAppWeb.Hooks.CustomRole do
  import Phoenix.LiveView
  
  def on_mount(:owner_or_admin, %{"id" => resource_id}, _session, socket) do
    scope = socket.assigns.current_scope
    
    cond do
      Scope.admin?(scope) -> {:cont, socket}
      owns_resource?(scope, resource_id) -> {:cont, socket}
      true -> {:halt, redirect(socket, to: "/unauthorized")}
    end
  end
end
```

## Best Practices

1. **Use the most specific role** - Prefer `:vendor` over `:authenticated` when only vendors should access
2. **Combine with route prefixes** - Keep URLs organized (`/admin/*`, `/vendor/*`, etc.)
3. **Consider permissions over roles** - Use permission-based checks for features that might span roles
4. **Document role requirements** - Add comments explaining why specific roles are required
5. **Test authorization** - Write tests to ensure proper access control

## Testing

Example test for role-based access:

```elixir
defmodule MyAppWeb.AdminLive.DashboardTest do
  use MyAppWeb.ConnCase
  import Phoenix.LiveViewTest

  test "redirects non-admin users", %{conn: conn} do
    vendor_user = user_fixture(%{is_vendor: true})
    conn = log_in_user(conn, vendor_user)
    
    {:error, {:redirect, %{to: "/vendor/dashboard"}}} = 
      live(conn, "/admin/dashboard")
  end
  
  test "allows admin access", %{conn: conn} do
    admin_user = user_fixture(%{is_admin: true})
    conn = log_in_user(conn, admin_user)
    
    {:ok, _view, html} = live(conn, "/admin/dashboard")
    assert html =~ "Admin Dashboard"
  end
end
```
