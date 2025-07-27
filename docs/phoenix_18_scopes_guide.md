# Phoenix 1.8 Scopes Guide - River Side Food Court

## Table of Contents
1. [Introduction to Phoenix 1.8 Scopes](#introduction)
2. [What are Scopes?](#what-are-scopes)
3. [Implementation in River Side](#implementation)
4. [Live Sessions and Authentication](#live-sessions)
5. [Scope Usage Patterns](#usage-patterns)
6. [Benefits and Best Practices](#benefits)
7. [Code Examples](#examples)

## Introduction to Phoenix 1.8 Scopes {#introduction}

Phoenix 1.8 introduced a new pattern for handling authentication and authorization context throughout your application. The River Side Food Court application demonstrates this pattern effectively.

## What are Scopes? {#what-are-scopes}

Scopes in Phoenix 1.8 are a way to encapsulate caller context - information about who is making a request and what permissions they have. Instead of passing user information through multiple function calls, scopes provide a clean, centralized way to manage this context.

### Key Concepts:

1. **Scope Struct**: A data structure that holds user information and permissions
2. **current_scope**: A standardized assign that carries scope information
3. **Live Sessions**: Groups of LiveView routes that share authentication requirements

## Implementation in River Side {#implementation}

### 1. The Scope Module

```elixir
# lib/river_side/accounts/scope.ex
defmodule RiverSide.Accounts.Scope do
  defstruct user: nil

  def for_user(%User{} = user) do
    %__MODULE__{user: user}
  end

  def for_user(nil), do: nil
end
```

This simple module:
- Defines a struct to hold user context
- Provides a constructor function `for_user/1`
- Returns `nil` for unauthenticated users

### 2. Authentication Pipeline

The authentication flow uses the scope pattern:

```elixir
# In UserAuth module
def fetch_current_scope_for_user(conn, _opts) do
  with {token, conn} <- ensure_user_token(conn),
       {user, token_inserted_at} <- Accounts.get_user_by_session_token(token) do
    conn
    |> assign(:current_scope, Scope.for_user(user))
    |> maybe_reissue_user_session_token(user, token_inserted_at)
  else
    nil -> assign(conn, :current_scope, Scope.for_user(nil))
  end
end
```

## Live Sessions and Authentication {#live-sessions}

### Router Configuration

The River Side router demonstrates three types of live sessions:

```elixir
# Public routes - no authentication required
live_session :public,
  on_mount: [{RiverSideWeb.UserAuth, :mount_current_scope}] do
  live "/", TableLive.Index, :index
  live "/customer/menu", CustomerLive.Menu, :index
  live "/customer/cart", CustomerLive.Cart, :index
end

# Authenticated routes - require logged in user
live_session :require_authenticated_user,
  on_mount: [{RiverSideWeb.UserAuth, :require_authenticated}] do
  live "/vendor/dashboard", VendorLive.Dashboard, :index
  live "/admin/dashboard", AdminLive.Dashboard, :index
  live "/cashier/dashboard", CashierLive.Dashboard, :index
end

# Current user routes - mount user but don't require auth
live_session :current_user,
  on_mount: [{RiverSideWeb.UserAuth, :mount_current_scope}] do
  live "/users/log-in", UserLive.Login, :new
end
```

### on_mount Callbacks

The `on_mount` callbacks handle different authentication scenarios:

```elixir
def on_mount(:mount_current_scope, _params, session, socket) do
  {:cont, mount_current_scope(socket, session)}
end

def on_mount(:require_authenticated, _params, session, socket) do
  socket = mount_current_scope(socket, session)
  
  if socket.assigns.current_scope && socket.assigns.current_scope.user do
    {:cont, socket}
  else
    socket =
      socket
      |> Phoenix.LiveView.put_flash(:error, "You must log in to access this page.")
      |> Phoenix.LiveView.redirect(to: ~p"/users/log-in")
    
    {:halt, socket}
  end
end
```

## Scope Usage Patterns {#usage-patterns}

### 1. In Controllers

```elixir
def index(conn, _params) do
  user = conn.assigns.current_scope.user
  # Use user information
end
```

### 2. In LiveViews

```elixir
def mount(_params, _session, socket) do
  user = socket.assigns.current_scope.user
  
  if user do
    # Authenticated user logic
  else
    # Guest logic
  end
end
```

### 3. Role-Based Access

You can extend the scope to include roles:

```elixir
defmodule MyApp.Accounts.Scope do
  defstruct [:user, :role, :permissions]
  
  def for_user(%User{} = user) do
    %__MODULE__{
      user: user,
      role: determine_role(user),
      permissions: load_permissions(user)
    }
  end
  
  def admin?(%__MODULE__{role: :admin}), do: true
  def admin?(_), do: false
  
  def vendor?(%__MODULE__{role: :vendor}), do: true
  def vendor?(_), do: false
end
```

### 4. In River Side's Multi-Role System

River Side could enhance its scope implementation for different user types:

```elixir
# Enhanced scope for River Side
defmodule RiverSide.Accounts.Scope do
  defstruct [:user, :type, :vendor_id, :permissions]
  
  def for_user(%User{} = user) do
    %__MODULE__{
      user: user,
      type: user.type,
      vendor_id: get_vendor_id(user),
      permissions: get_permissions(user.type)
    }
  end
  
  def can_manage_orders?(%__MODULE__{type: type}) do
    type in [:vendor, :admin]
  end
  
  def can_process_payments?(%__MODULE__{type: type}) do
    type in [:cashier, :admin]
  end
end
```

## Benefits and Best Practices {#benefits}

### Benefits of Using Scopes

1. **Centralized Authentication Logic**: All auth logic is in one place
2. **Consistent API**: Same pattern across controllers and LiveViews
3. **Type Safety**: Struct-based approach catches errors at compile time
4. **Extensibility**: Easy to add new fields and permissions
5. **Testing**: Easier to mock and test authentication scenarios

### Best Practices

1. **Keep Scopes Lightweight**: Don't load unnecessary data
   ```elixir
   # Good - Load only what's needed
   %Scope{user: user, vendor_id: user.vendor_id}
   
   # Bad - Loading everything
   %Scope{user: user, orders: load_all_orders(user), ...}
   ```

2. **Use Pattern Matching**: Leverage Elixir's pattern matching
   ```elixir
   def handle_event("update", params, %{assigns: %{current_scope: %{user: %User{} = user}}} = socket) do
     # Authenticated user logic
   end
   
   def handle_event("update", params, %{assigns: %{current_scope: nil}} = socket) do
     # Guest logic
   end
   ```

3. **Consistent Naming**: Always use `current_scope` as the assign name

4. **Null Object Pattern**: Return a scope even for guests
   ```elixir
   def for_user(nil), do: %__MODULE__{user: nil, permissions: guest_permissions()}
   ```

## Code Examples {#examples}

### Example 1: Protected LiveView

```elixir
defmodule MyAppWeb.AdminLive do
  use MyAppWeb, :live_view
  
  def mount(_params, _session, socket) do
    # current_scope is already assigned by on_mount callback
    case socket.assigns.current_scope do
      %Scope{user: %User{type: :admin}} ->
        {:ok, load_admin_data(socket)}
      
      _ ->
        {:ok,
         socket
         |> put_flash(:error, "Unauthorized")
         |> redirect(to: ~p"/")}
    end
  end
end
```

### Example 2: Conditional Rendering

```heex
<%= if @current_scope && @current_scope.user do %>
  <div>Welcome, <%= @current_scope.user.name %>!</div>
  
  <%= if RiverSide.Accounts.Scope.vendor?(@current_scope) do %>
    <.link href={~p"/vendor/dashboard"}>Vendor Dashboard</.link>
  <% end %>
<% else %>
  <.link href={~p"/users/log-in"}>Log In</.link>
<% end %>
```

### Example 3: PubSub with Scopes

```elixir
def subscribe_to_updates(%Scope{user: %User{id: user_id}} = scope) do
  if Scope.can_view_all_orders?(scope) do
    Phoenix.PubSub.subscribe(MyApp.PubSub, "orders:all")
  else
    Phoenix.PubSub.subscribe(MyApp.PubSub, "orders:user:#{user_id}")
  end
end
```

### Example 4: Testing with Scopes

```elixir
defmodule MyAppWeb.AdminLiveTest do
  use MyAppWeb.ConnCase, async: true
  
  setup :register_and_log_in_admin_user
  
  test "shows admin dashboard", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/admin/dashboard")
    
    assert has_element?(view, "h1", "Admin Dashboard")
  end
  
  test "redirects regular users", %{conn: conn} do
    regular_user = user_fixture(type: :customer)
    conn = log_in_user(conn, regular_user)
    
    {:error, {:redirect, %{to: "/"}}} = live(conn, ~p"/admin/dashboard")
  end
end
```

## Migration Guide

If you're upgrading an existing Phoenix app to use scopes:

1. Create a Scope module
2. Update your authentication plugs to use `current_scope`
3. Add `on_mount` callbacks to your live sessions
4. Update your templates and LiveViews to use `@current_scope`
5. Remove direct user assigns in favor of scope access

## Conclusion

Phoenix 1.8's scope pattern provides a clean, extensible way to handle authentication and authorization throughout your application. River Side Food Court demonstrates basic usage, but the pattern can be extended to handle complex multi-tenant, multi-role applications with ease.

The key is to think of scopes as the "context" of who is making a request and what they're allowed to do, making your code more maintainable and your authorization logic more centralized.