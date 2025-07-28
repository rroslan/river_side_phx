# Router Migration Guide - Using RequireRole Hook

This guide shows how the router.ex file was updated to use the new RequireRole hook for cleaner, more concise authorization.

## Key Principles

1. **Single hook for both mounting and authorization** - The RequireRole hook now handles both mounting the current scope and checking authorization in one step.

2. **Automatic scope detection** - The hook automatically mounts the appropriate scope (user or customer) based on session data.

3. **Simplified syntax** - No need to chain multiple hooks; RequireRole does it all.

## Migration Examples

### Admin Routes

**Before:**
```elixir
live_session :admin,
  on_mount: [{RiverSideWeb.UserAuth, :require_admin_scope}] do
  live "/dashboard", AdminLive.Dashboard, :index
  live "/vendors", AdminLive.VendorList, :index
end
```

**After:**
```elixir
live_session :admin,
  on_mount: [{RiverSideWeb.Hooks.RequireRole, :admin}] do
  live "/dashboard", AdminLive.Dashboard, :index
  live "/vendors", AdminLive.VendorList, :index
end
```

### Vendor Routes

**Before:**
```elixir
live_session :vendor,
  on_mount: [{RiverSideWeb.UserAuth, :require_vendor_scope}] do
  live "/dashboard", VendorLive.Dashboard, :index
  live "/profile/edit", VendorLive.ProfileEdit, :edit
  live "/menu/new", VendorLive.MenuItemForm, :new
  live "/menu/:id/edit", VendorLive.MenuItemForm, :edit
end
```

**After:**
```elixir
live_session :vendor,
  on_mount: [{RiverSideWeb.Hooks.RequireRole, :vendor}] do
  live "/dashboard", VendorLive.Dashboard, :index
  live "/profile/edit", VendorLive.ProfileEdit, :edit
  live "/menu/new", VendorLive.MenuItemForm, :new
  live "/menu/:id/edit", VendorLive.MenuItemForm, :edit
end
```

### Cashier Routes

**Before:**
```elixir
live_session :cashier,
  on_mount: [{RiverSideWeb.UserAuth, :require_cashier_scope}] do
  live "/dashboard", CashierLive.Dashboard, :index
end
```

**After:**
```elixir
live_session :cashier,
  on_mount: [{RiverSideWeb.Hooks.RequireRole, :cashier}] do
  live "/dashboard", CashierLive.Dashboard, :index
end
```

### Customer Routes

**Before:**
```elixir
live_session :customer,
  on_mount: [{RiverSideWeb.UserAuth, :mount_customer_scope}] do
  live "/menu", CustomerLive.Menu, :index
  live "/cart", CustomerLive.Cart, :index
  live "/orders", CustomerLive.OrderTracking, :index
end
```

**After:**
```elixir
live_session :customer,
  on_mount: [{RiverSideWeb.Hooks.RequireRole, :customer}] do
  live "/menu", CustomerLive.Menu, :index
  live "/cart", CustomerLive.Cart, :index
  live "/orders", CustomerLive.OrderTracking, :index
end
```

### Authenticated User Routes

**Before:**
```elixir
live_session :authenticated_user,
  on_mount: [{RiverSideWeb.UserAuth, :require_authenticated}] do
  live "/users/settings", UserLive.Settings, :edit
  live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
end
```

**After:**
```elixir
live_session :authenticated_user,
  on_mount: [{RiverSideWeb.Hooks.RequireRole, :authenticated}] do
  live "/users/settings", UserLive.Settings, :edit
  live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
end
```

## Benefits of This Approach

1. **Cleaner code** - Single hook instead of multiple for common use cases
2. **Less boilerplate** - No need to remember to mount scope before checking roles
3. **Backwards compatible** - The original UserAuth hooks still work if needed
4. **Smart scope detection** - Automatically handles user vs customer sessions
5. **Consistent API** - Same hook pattern for all role types

## Advanced Usage

### Multiple Roles

```elixir
live_session :staff_area,
  on_mount: [{RiverSideWeb.Hooks.RequireRole, {:any, [:admin, :cashier]}}] do
  live "/staff/reports", StaffLive.Reports, :index
end
```

### Permission-Based Access

```elixir
live_session :financial,
  on_mount: [{RiverSideWeb.Hooks.RequireRole, {:permission, :process_payments}}] do
  live "/payments/process", PaymentLive.Process, :new
end
```

### Adding More Hooks

```elixir
live_session :admin_with_logging,
  on_mount: [
    {RiverSideWeb.Hooks.RequireRole, :admin},
    {RiverSideWeb.Hooks.ActivityLogger, :log_access},
    {RiverSideWeb.Hooks.AdminLayout, :set_layout}
  ] do
  live "/admin/sensitive", AdminLive.Sensitive, :index
end
```

## Notes

- Routes that don't require authentication (like the home page and login) don't need RequireRole
- The customer checkin route still uses `mount_guest_scope` since customers aren't authenticated yet
- RequireRole automatically handles scope mounting, so you don't need separate mount hooks
- The pipe_through [:browser, :require_authenticated_user] is still used for initial Plug-level authentication
- The browser pipeline already includes `fetch_current_scope_for_user` which loads the scope into conn.assigns

## How It Works

1. **Browser Pipeline** - The `fetch_current_scope_for_user` plug in the browser pipeline loads the current scope from the session token
2. **Plug Authentication** - The `require_authenticated_user` plug verifies basic authentication at the Plug level
3. **LiveView Mount** - RequireRole hook ensures the scope is available in the socket and checks the specific role requirement
4. **Smart Detection** - For customer routes, it checks both URL params and session data to find customer info