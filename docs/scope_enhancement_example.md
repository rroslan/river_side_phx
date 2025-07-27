# River Side Food Court - Enhanced Scope Implementation Example

This document shows how River Side could enhance its current scope implementation to better handle its multi-role system (admin, vendor, cashier, customer).

## Current Implementation

Currently, River Side has a basic scope:

```elixir
defmodule RiverSide.Accounts.Scope do
  defstruct user: nil

  def for_user(%User{} = user) do
    %__MODULE__{user: user}
  end

  def for_user(nil), do: nil
end
```

## Enhanced Implementation

### 1. Enhanced Scope Module

```elixir
defmodule RiverSide.Accounts.Scope do
  @moduledoc """
  Enhanced scope implementation for River Side Food Court's multi-role system.
  """

  alias RiverSide.Accounts.User
  alias RiverSide.Vendors

  defstruct [:user, :role, :vendor, :permissions, :session_id]

  @doc """
  Creates an enhanced scope for the given user.
  """
  def for_user(%User{} = user) do
    %__MODULE__{
      user: user,
      role: determine_role(user),
      vendor: load_vendor_if_applicable(user),
      permissions: build_permissions(user),
      session_id: generate_session_id()
    }
  end

  def for_user(nil) do
    %__MODULE__{
      user: nil,
      role: :guest,
      vendor: nil,
      permissions: guest_permissions(),
      session_id: generate_session_id()
    }
  end

  # Role determination based on user type
  defp determine_role(%User{type: type}) do
    case type do
      "admin" -> :admin
      "vendor" -> :vendor
      "cashier" -> :cashier
      _ -> :guest
    end
  end

  # Load vendor data for vendor users
  defp load_vendor_if_applicable(%User{type: "vendor", id: user_id}) do
    case Vendors.get_vendor_by_user_id(user_id) do
      nil -> nil
      vendor -> vendor
    end
  end

  defp load_vendor_if_applicable(_user), do: nil

  # Build permissions based on role
  defp build_permissions(%User{type: type}) do
    case type do
      "admin" -> admin_permissions()
      "vendor" -> vendor_permissions()
      "cashier" -> cashier_permissions()
      _ -> guest_permissions()
    end
  end

  defp admin_permissions do
    %{
      can_view_all_orders: true,
      can_manage_vendors: true,
      can_process_payments: true,
      can_view_analytics: true,
      can_manage_users: true,
      can_access_admin_dashboard: true
    }
  end

  defp vendor_permissions do
    %{
      can_view_own_orders: true,
      can_manage_own_menu: true,
      can_update_order_status: true,
      can_view_own_analytics: true,
      can_access_vendor_dashboard: true
    }
  end

  defp cashier_permissions do
    %{
      can_process_payments: true,
      can_view_payment_queue: true,
      can_mark_orders_paid: true,
      can_access_cashier_dashboard: true
    }
  end

  defp guest_permissions do
    %{
      can_view_menu: true,
      can_place_orders: true,
      can_track_orders: true
    }
  end

  defp generate_session_id do
    :crypto.strong_rand_bytes(16) |> Base.encode64()
  end

  # Helper functions for checking permissions
  def admin?(%__MODULE__{role: :admin}), do: true
  def admin?(_), do: false

  def vendor?(%__MODULE__{role: :vendor}), do: true
  def vendor?(_), do: false

  def cashier?(%__MODULE__{role: :cashier}), do: true
  def cashier?(_), do: false

  def guest?(%__MODULE__{role: :guest}), do: true
  def guest?(%__MODULE__{user: nil}), do: true
  def guest?(_), do: false

  def authenticated?(%__MODULE__{user: nil}), do: false
  def authenticated?(%__MODULE__{user: _}), do: true

  def can?(%__MODULE__{permissions: perms}, action) when is_atom(action) do
    Map.get(perms, action, false)
  end

  def can?(%__MODULE__{} = scope, action, resource) do
    case {action, resource} do
      {:view_order, order} -> can_view_order?(scope, order)
      {:update_menu_item, item} -> can_update_menu_item?(scope, item)
      {:process_payment, order} -> can_process_payment?(scope, order)
      _ -> false
    end
  end

  defp can_view_order?(%__MODULE__{role: :admin}, _order), do: true
  defp can_view_order?(%__MODULE__{role: :vendor, vendor: vendor}, order) do
    order.vendor_id == vendor.id
  end
  defp can_view_order?(%__MODULE__{role: :cashier}, _order), do: true
  defp can_view_order?(_, _), do: false

  defp can_update_menu_item?(%__MODULE__{role: :admin}, _item), do: true
  defp can_update_menu_item?(%__MODULE__{role: :vendor, vendor: vendor}, item) do
    item.vendor_id == vendor.id
  end
  defp can_update_menu_item?(_, _), do: false

  defp can_process_payment?(%__MODULE__{} = scope, _order) do
    scope.role in [:admin, :cashier]
  end
end
```

### 2. Updated Router with Role-Based Live Sessions

```elixir
defmodule RiverSideWeb.Router do
  use RiverSideWeb, :router

  # ... pipelines ...

  # Public routes
  scope "/", RiverSideWeb do
    pipe_through :browser

    live_session :public,
      on_mount: [{RiverSideWeb.UserAuth, :mount_current_scope}] do
      live "/", TableLive.Index, :index
      live "/customer/checkin/:table_number", CustomerLive.Checkin, :new
      live "/customer/menu", CustomerLive.Menu, :index
      live "/customer/cart", CustomerLive.Cart, :index
      live "/customer/orders", CustomerLive.OrderTracking, :index
    end
  end

  # Admin routes
  scope "/admin", RiverSideWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :admin,
      on_mount: [{RiverSideWeb.UserAuth, :require_admin}] do
      live "/dashboard", AdminLive.Dashboard, :index
      live "/vendors", AdminLive.VendorList, :index
      live "/analytics", AdminLive.Analytics, :index
      live "/users", AdminLive.UserManagement, :index
    end
  end

  # Vendor routes
  scope "/vendor", RiverSideWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :vendor,
      on_mount: [{RiverSideWeb.UserAuth, :require_vendor}] do
      live "/dashboard", VendorLive.Dashboard, :index
      live "/menu", VendorLive.MenuManagement, :index
      live "/menu/new", VendorLive.MenuItemForm, :new
      live "/menu/:id/edit", VendorLive.MenuItemForm, :edit
      live "/analytics", VendorLive.Analytics, :index
    end
  end

  # Cashier routes
  scope "/cashier", RiverSideWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :cashier,
      on_mount: [{RiverSideWeb.UserAuth, :require_cashier}] do
      live "/dashboard", CashierLive.Dashboard, :index
      live "/payments", CashierLive.PaymentQueue, :index
    end
  end
end
```

### 3. Enhanced UserAuth Module

```elixir
defmodule RiverSideWeb.UserAuth do
  # ... existing code ...

  def on_mount(:require_admin, _params, session, socket) do
    socket = mount_current_scope(socket, session)

    if RiverSide.Accounts.Scope.admin?(socket.assigns.current_scope) do
      {:cont, socket}
    else
      {:halt, redirect_unauthorized(socket, "Admin access required")}
    end
  end

  def on_mount(:require_vendor, _params, session, socket) do
    socket = mount_current_scope(socket, session)

    if RiverSide.Accounts.Scope.vendor?(socket.assigns.current_scope) do
      {:cont, socket}
    else
      {:halt, redirect_unauthorized(socket, "Vendor access required")}
    end
  end

  def on_mount(:require_cashier, _params, session, socket) do
    socket = mount_current_scope(socket, session)

    if RiverSide.Accounts.Scope.cashier?(socket.assigns.current_scope) do
      {:cont, socket}
    else
      {:halt, redirect_unauthorized(socket, "Cashier access required")}
    end
  end

  defp redirect_unauthorized(socket, message) do
    socket
    |> Phoenix.LiveView.put_flash(:error, message)
    |> Phoenix.LiveView.redirect(to: determine_redirect_path(socket))
  end

  defp determine_redirect_path(socket) do
    case socket.assigns.current_scope do
      %{user: nil} -> ~p"/users/log-in"
      %{role: :vendor} -> ~p"/vendor/dashboard"
      %{role: :cashier} -> ~p"/cashier/dashboard"
      _ -> ~p"/"
    end
  end
end
```

### 4. Using Enhanced Scopes in LiveViews

```elixir
defmodule RiverSideWeb.VendorLive.Dashboard do
  use RiverSideWeb, :live_view

  alias RiverSide.Vendors
  alias RiverSide.Accounts.Scope

  def mount(_params, _session, socket) do
    scope = socket.assigns.current_scope

    # The scope already contains vendor information
    vendor = scope.vendor

    # Subscribe to vendor-specific updates
    Vendors.subscribe_to_vendor_updates(vendor.id)

    {:ok,
     socket
     |> assign(vendor: vendor)
     |> load_vendor_data()}
  end

  def handle_event("update_order_status", %{"order_id" => order_id, "status" => status}, socket) do
    order = Vendors.get_order!(order_id)

    # Use scope to check permissions
    if Scope.can?(socket.assigns.current_scope, :update_order, order) do
      case Vendors.update_order_status(order, %{status: status}) do
        {:ok, _order} ->
          {:noreply, put_flash(socket, :info, "Order status updated")}
        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to update order")}
      end
    else
      {:noreply, put_flash(socket, :error, "Unauthorized")}
    end
  end
end
```

### 5. Conditional UI Based on Scope

```heex
<!-- In a shared layout component -->
<nav class="navbar">
  <%= if Scope.authenticated?(@current_scope) do %>
    <div class="user-menu">
      <span>Welcome, <%= @current_scope.user.name %></span>
      
      <%= if Scope.admin?(@current_scope) do %>
        <.link href={~p"/admin/dashboard"} class="nav-link">Admin Dashboard</.link>
      <% end %>
      
      <%= if Scope.vendor?(@current_scope) do %>
        <.link href={~p"/vendor/dashboard"} class="nav-link">Vendor Dashboard</.link>
        <span class="vendor-name"><%= @current_scope.vendor.name %></span>
      <% end %>
      
      <%= if Scope.cashier?(@current_scope) do %>
        <.link href={~p"/cashier/dashboard"} class="nav-link">Process Payments</.link>
      <% end %>
      
      <.link href={~p"/users/log-out"} method="delete" class="nav-link">Log Out</.link>
    </div>
  <% else %>
    <.link href={~p"/users/log-in"} class="nav-link">Log In</.link>
  <% end %>
</nav>

<!-- In vendor dashboard -->
<%= if Scope.can?(@current_scope, :view_analytics) do %>
  <.live_component
    module={VendorAnalyticsComponent}
    id="analytics"
    vendor={@current_scope.vendor}
  />
<% end %>
```

### 6. Testing with Enhanced Scopes

```elixir
defmodule RiverSideWeb.VendorLive.DashboardTest do
  use RiverSideWeb.ConnCase, async: true

  alias RiverSide.Accounts.Scope

  setup do
    vendor_user = user_fixture(type: "vendor")
    vendor = vendor_fixture(user_id: vendor_user.id)
    
    scope = Scope.for_user(vendor_user)
    
    %{user: vendor_user, vendor: vendor, scope: scope}
  end

  test "vendor can view their own orders", %{conn: conn, user: user} do
    conn = log_in_user(conn, user)
    {:ok, view, _html} = live(conn, ~p"/vendor/dashboard")
    
    assert has_element?(view, "[data-test='vendor-orders']")
  end

  test "vendor cannot access admin dashboard", %{conn: conn, user: user} do
    conn = log_in_user(conn, user)
    
    assert {:error, {:redirect, %{to: "/vendor/dashboard"}}} = 
      live(conn, ~p"/admin/dashboard")
  end

  test "scope correctly identifies vendor permissions", %{scope: scope} do
    assert Scope.vendor?(scope)
    assert Scope.can?(scope, :manage_own_menu)
    refute Scope.can?(scope, :manage_vendors)
  end
end
```

## Benefits of This Enhancement

1. **Role-Based Access Control**: Clear separation of permissions by role
2. **Resource-Level Authorization**: Can check permissions on specific resources
3. **Preloaded Context**: Vendor data is loaded once in the scope
4. **Type Safety**: Pattern matching on scope roles
5. **Testability**: Easy to test different permission scenarios
6. **Extensibility**: Easy to add new roles or permissions

## Migration Path

1. Update the Scope module with enhanced fields
2. Add role-specific on_mount callbacks
3. Update LiveViews to use scope permissions
4. Add tests for permission checks
5. Gradually migrate from direct user checks to scope checks

This enhancement makes River Side's authorization system more robust while maintaining the clean architecture that Phoenix 1.8 scopes provide.