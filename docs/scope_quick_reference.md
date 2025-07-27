# Phoenix 1.8 Scopes - Quick Reference

## What are Scopes?

Scopes are Phoenix 1.8's way of handling authentication context throughout your application. Instead of passing user data through multiple function calls, scopes provide a centralized, consistent way to manage who is making a request and what they can do.

## Key Components

### 1. Scope Struct
```elixir
defmodule MyApp.Accounts.Scope do
  defstruct [:user, :role, :permissions]
  
  def for_user(user), do: %__MODULE__{user: user}
end
```

### 2. Router Setup
```elixir
# Public routes - no auth required
live_session :public,
  on_mount: [{MyAppWeb.UserAuth, :mount_current_scope}] do
  live "/", PageLive, :index
end

# Protected routes - auth required
live_session :authenticated,
  on_mount: [{MyAppWeb.UserAuth, :require_authenticated}] do
  live "/dashboard", DashboardLive, :index
end
```

### 3. on_mount Callbacks
```elixir
def on_mount(:mount_current_scope, _params, session, socket) do
  {:cont, assign_scope(socket, session)}
end

def on_mount(:require_authenticated, _params, session, socket) do
  socket = assign_scope(socket, session)
  
  if authenticated?(socket.assigns.current_scope) do
    {:cont, socket}
  else
    {:halt, redirect_to_login(socket)}
  end
end
```

## Common Patterns

### Accessing Current User
```elixir
# In LiveView
def mount(_params, _session, socket) do
  user = socket.assigns.current_scope.user
  # ...
end

# In Controller
def index(conn, _params) do
  user = conn.assigns.current_scope.user
  # ...
end
```

### Conditional Rendering
```heex
<%= if @current_scope && @current_scope.user do %>
  <p>Welcome, <%= @current_scope.user.name %>!</p>
<% else %>
  <.link href={~p"/login"}>Log In</.link>
<% end %>
```

### Permission Checks
```elixir
# In Scope module
def can?(%__MODULE__{permissions: perms}, action) do
  Map.get(perms, action, false)
end

# Usage
if Scope.can?(@current_scope, :edit_posts) do
  # Allow editing
end
```

### Role-Based Access
```elixir
# In Scope module
def admin?(%__MODULE__{role: :admin}), do: true
def admin?(_), do: false

# Usage in template
<%= if Scope.admin?(@current_scope) do %>
  <.link href={~p"/admin"}>Admin Panel</.link>
<% end %>
```

## River Side Implementation

### Current Basic Implementation
```elixir
# Simple scope with just user
defmodule RiverSide.Accounts.Scope do
  defstruct user: nil
  
  def for_user(user), do: %__MODULE__{user: user}
  def for_user(nil), do: nil
end
```

### Router Configuration
```elixir
# Public customer routes
live_session :public,
  on_mount: [{RiverSideWeb.UserAuth, :mount_current_scope}] do
  live "/customer/menu", CustomerLive.Menu, :index
end

# Vendor routes
live_session :require_authenticated_user,
  on_mount: [{RiverSideWeb.UserAuth, :require_authenticated}] do
  live "/vendor/dashboard", VendorLive.Dashboard, :index
end
```

## Benefits

1. **Centralized Auth Logic**: All authentication logic in one place
2. **Consistent API**: Same pattern in controllers and LiveViews
3. **Type Safety**: Struct-based approach catches errors early
4. **Extensible**: Easy to add new fields and permissions
5. **Testable**: Simple to mock different user scenarios

## Common Pitfalls to Avoid

1. **Don't Overload Scopes**: Keep them lightweight
   ```elixir
   # Bad - Loading too much
   %Scope{user: user, all_orders: load_orders(), all_products: load_products()}
   
   # Good - Load only essentials
   %Scope{user: user, role: user.role}
   ```

2. **Always Check for nil**: Handle unauthenticated users
   ```elixir
   # Bad
   @current_scope.user.name
   
   # Good
   @current_scope && @current_scope.user && @current_scope.user.name
   ```

3. **Use Pattern Matching**: Leverage Elixir's strengths
   ```elixir
   case socket.assigns.current_scope do
     %Scope{user: %User{role: :admin}} -> admin_logic()
     %Scope{user: %User{}} -> user_logic()
     _ -> guest_logic()
   end
   ```

## Testing

```elixir
# Test different scope scenarios
test "admin can access admin panel", %{conn: conn} do
  admin = user_fixture(role: :admin)
  conn = log_in_user(conn, admin)
  
  {:ok, _view, html} = live(conn, ~p"/admin")
  assert html =~ "Admin Dashboard"
end

test "regular user cannot access admin panel", %{conn: conn} do
  user = user_fixture(role: :user)
  conn = log_in_user(conn, user)
  
  assert {:error, {:redirect, %{to: "/"}}} = live(conn, ~p"/admin")
end
```

## Quick Setup for New Project

1. Create Scope module in `lib/my_app/accounts/scope.ex`
2. Add `fetch_current_scope_for_user/2` plug to browser pipeline
3. Create on_mount callbacks in UserAuth module
4. Update router with live_session groups
5. Access scope via `@current_scope` in templates

That's it! Scopes provide a clean, Phoenix 1.8-way to handle authentication context.