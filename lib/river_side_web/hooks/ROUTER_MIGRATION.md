# Router Migration Guide - Using RequireRole Hook

This guide shows how the router.ex file was updated to use the new RequireRole hook while maintaining compatibility with the existing UserAuth system.

## Key Principles

1. **Keep UserAuth for scope mounting** - UserAuth hooks like `mount_current_scope` and `mount_customer_scope` are still needed to properly load the user's scope into the socket assigns.

2. **Add RequireRole for authorization** - The RequireRole hook performs the actual authorization check after the scope is mounted.

3. **Order matters** - Always mount the scope first, then check authorization.

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
  on_mount: [
    {RiverSideWeb.UserAuth, :mount_current_scope},
    {RiverSideWeb.Hooks.RequireRole, :admin}
  ] do
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
  on_mount: [
    {RiverSideWeb.UserAuth, :mount_current_scope},
    {RiverSideWeb.Hooks.RequireRole, :vendor}
  ] do
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
  on_mount: [
    {RiverSideWeb.UserAuth, :mount_current_scope},
    {RiverSideWeb.Hooks.RequireRole, :cashier}
  ] do
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
  on_mount: [
    {RiverSideWeb.UserAuth, :mount_customer_scope},
    {RiverSideWeb.Hooks.RequireRole, :customer}
  ] do
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
  on_mount: [
    {RiverSideWeb.UserAuth, :mount_current_scope},
    {RiverSideWeb.Hooks.RequireRole, :authenticated}
  ] do
  live "/users/settings", UserLive.Settings, :edit
  live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
end
```

## Benefits of This Approach

1. **Separation of concerns** - Scope mounting and authorization are separate steps
2. **Flexibility** - Easy to add additional hooks between mounting and authorization
3. **Backwards compatible** - The original UserAuth hooks still work if needed
4. **Clearer intent** - It's obvious what each hook is doing

## Advanced Usage

### Multiple Roles

```elixir
live_session :staff_area,
  on_mount: [
    {RiverSideWeb.UserAuth, :mount_current_scope},
    {RiverSideWeb.Hooks.RequireRole, {:any, [:admin, :cashier]}}
  ] do
  live "/staff/reports", StaffLive.Reports, :index
end
```

### Permission-Based Access

```elixir
live_session :financial,
  on_mount: [
    {RiverSideWeb.UserAuth, :mount_current_scope},
    {RiverSideWeb.Hooks.RequireRole, {:permission, :process_payments}}
  ] do
  live "/payments/process", PaymentLive.Process, :new
end
```

### Adding More Hooks

```elixir
live_session :admin_with_logging,
  on_mount: [
    {RiverSideWeb.UserAuth, :mount_current_scope},
    {RiverSideWeb.Hooks.RequireRole, :admin},
    {RiverSideWeb.Hooks.ActivityLogger, :log_access},
    {RiverSideWeb.Hooks.AdminLayout, :set_layout}
  ] do
  live "/admin/sensitive", AdminLive.Sensitive, :index
end
```

## Notes

- Routes that don't require authentication (like the home page and login) don't need RequireRole
- The customer checkin route uses `mount_guest_scope` since customers aren't authenticated yet
- The order of hooks matters - always mount scope before checking authorization
- The pipe_through [:browser, :require_authenticated_user] is still used for initial Plug-level authentication