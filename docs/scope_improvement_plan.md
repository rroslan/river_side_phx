# River Side Food Court - Scope Implementation Improvement Plan

## Executive Summary

This document outlines a comprehensive plan to improve River Side Food Court's implementation of Phoenix 1.8 scopes. The current implementation uses basic scopes but doesn't leverage their full potential for the multi-role system (admin, vendor, cashier, customer).

## Current State Analysis

### What's Working
- Basic scope structure exists (`RiverSide.Accounts.Scope`)
- Authentication pipeline uses `current_scope`
- Live sessions are properly configured

### Current Limitations
1. **Minimal Scope Data**: Only stores user, missing role and context information
2. **Scattered Authorization**: Permission checks are spread across LiveViews
3. **Repeated Data Loading**: Vendor data is loaded multiple times
4. **No Customer Context**: Customer sessions don't utilize scopes
5. **Inconsistent Permission Checks**: No centralized authorization logic

## Improvement Plan

### Phase 1: Enhanced Scope Structure

#### 1.1 Update Scope Module

**Current Implementation:**
```elixir
defmodule RiverSide.Accounts.Scope do
  defstruct user: nil
  
  def for_user(%User{} = user) do
    %__MODULE__{user: user}
  end
  
  def for_user(nil), do: nil
end
```

**Improved Implementation:**
```elixir
defmodule RiverSide.Accounts.Scope do
  @moduledoc """
  Enhanced scope for River Side's multi-role food court system.
  Handles admin, vendor, cashier, and customer contexts.
  """
  
  alias RiverSide.Accounts.User
  alias RiverSide.Vendors
  alias RiverSide.Vendors.Vendor
  
  defstruct [
    :user,
    :type,           # :admin, :vendor, :cashier, :customer, :guest
    :vendor,         # Preloaded vendor for vendor users
    :permissions,    # Map of allowed actions
    :customer_info,  # For customer sessions (phone, table_number)
    :session_id,     # Unique session identifier
    :expires_at      # Session expiration for customers
  ]
  
  @doc "Creates a scope for authenticated users"
  def for_user(%User{} = user) do
    base_scope = %__MODULE__{
      user: user,
      type: determine_type(user),
      session_id: generate_session_id(),
      expires_at: nil
    }
    
    base_scope
    |> load_vendor_context()
    |> assign_permissions()
  end
  
  @doc "Creates a scope for guest customers"
  def for_customer(phone, table_number) do
    %__MODULE__{
      user: nil,
      type: :customer,
      customer_info: %{
        phone: phone,
        table_number: table_number
      },
      permissions: customer_permissions(),
      session_id: generate_session_id(),
      expires_at: DateTime.add(DateTime.utc_now(), 4, :hour)
    }
  end
  
  @doc "Creates an empty scope for guests"
  def for_guest do
    %__MODULE__{
      user: nil,
      type: :guest,
      permissions: guest_permissions(),
      session_id: generate_session_id()
    }
  end
  
  # Type determination
  defp determine_type(%User{type: type}) do
    case type do
      "admin" -> :admin
      "vendor" -> :vendor
      "cashier" -> :cashier
      _ -> :guest
    end
  end
  
  # Load vendor context for vendor users
  defp load_vendor_context(%{type: :vendor, user: %{id: user_id}} = scope) do
    case Vendors.get_vendor_by_user_id(user_id) do
      %Vendor{} = vendor -> %{scope | vendor: vendor}
      nil -> scope
    end
  end
  defp load_vendor_context(scope), do: scope
  
  # Assign permissions based on type
  defp assign_permissions(%{type: type} = scope) do
    permissions = case type do
      :admin -> admin_permissions()
      :vendor -> vendor_permissions()
      :cashier -> cashier_permissions()
      :customer -> customer_permissions()
      _ -> guest_permissions()
    end
    
    %{scope | permissions: permissions}
  end
end
```

#### 1.2 Permission Maps

```elixir
defmodule RiverSide.Accounts.Permissions do
  @moduledoc "Centralized permission definitions"
  
  def admin_permissions do
    %{
      # Vendor management
      view_all_vendors: true,
      create_vendor: true,
      update_vendor: true,
      delete_vendor: true,
      
      # Order management
      view_all_orders: true,
      update_any_order: true,
      cancel_any_order: true,
      
      # Financial
      view_all_transactions: true,
      process_refunds: true,
      view_analytics: true,
      
      # System
      manage_users: true,
      view_system_logs: true,
      access_admin_dashboard: true
    }
  end
  
  def vendor_permissions do
    %{
      # Menu management
      view_own_menu: true,
      create_menu_item: true,
      update_own_menu_item: true,
      delete_own_menu_item: true,
      
      # Order management
      view_own_orders: true,
      update_own_order_status: true,
      cancel_own_order: true,
      
      # Analytics
      view_own_analytics: true,
      view_own_transactions: true,
      
      # Profile
      update_own_profile: true,
      access_vendor_dashboard: true
    }
  end
  
  def cashier_permissions do
    %{
      # Payment processing
      process_payments: true,
      mark_orders_paid: true,
      view_payment_queue: true,
      process_refunds: true,
      
      # Order viewing
      view_all_orders: true,
      view_order_details: true,
      
      # Dashboard
      access_cashier_dashboard: true,
      view_daily_transactions: true
    }
  end
  
  def customer_permissions do
    %{
      # Menu and ordering
      view_menu: true,
      place_order: true,
      view_own_orders: true,
      track_orders: true,
      
      # Cart
      manage_cart: true,
      checkout: true
    }
  end
  
  def guest_permissions do
    %{
      view_menu: true,
      view_table_availability: true
    }
  end
end
```

### Phase 2: Authorization Helpers

#### 2.1 Scope Query Functions

```elixir
defmodule RiverSide.Accounts.Scope do
  # ... previous code ...
  
  # Role checks
  def admin?(%__MODULE__{type: :admin}), do: true
  def admin?(_), do: false
  
  def vendor?(%__MODULE__{type: :vendor}), do: true
  def vendor?(_), do: false
  
  def cashier?(%__MODULE__{type: :cashier}), do: true
  def cashier?(_), do: false
  
  def customer?(%__MODULE__{type: :customer}), do: true
  def customer?(_), do: false
  
  def authenticated?(%__MODULE__{user: %User{}}), do: true
  def authenticated?(_), do: false
  
  # Permission checks
  def can?(%__MODULE__{permissions: perms}, action) when is_atom(action) do
    Map.get(perms, action, false)
  end
  
  def can?(_scope, _action), do: false
  
  # Resource-based authorization
  def can?(%__MODULE__{} = scope, action, resource) do
    RiverSide.Authorization.check(scope, action, resource)
  end
  
  # Vendor-specific helpers
  def owns_vendor?(%__MODULE__{type: :vendor, vendor: %{id: vendor_id}}, %{vendor_id: resource_vendor_id}) do
    vendor_id == resource_vendor_id
  end
  def owns_vendor?(_, _), do: false
  
  # Customer-specific helpers
  def active_customer?(%__MODULE__{type: :customer, expires_at: expires_at}) do
    DateTime.compare(expires_at, DateTime.utc_now()) == :gt
  end
  def active_customer?(_), do: false
  
  def customer_phone(%__MODULE__{type: :customer, customer_info: %{phone: phone}}), do: phone
  def customer_phone(_), do: nil
  
  def customer_table(%__MODULE__{type: :customer, customer_info: %{table_number: table}}), do: table
  def customer_table(_), do: nil
end
```

#### 2.2 Authorization Module

```elixir
defmodule RiverSide.Authorization do
  @moduledoc "Centralized authorization logic"
  
  alias RiverSide.Accounts.Scope
  alias RiverSide.Vendors.{Order, MenuItem}
  
  def check(%Scope{} = scope, action, resource) do
    case {action, resource} do
      # Order authorization
      {:view, %Order{} = order} -> 
        can_view_order?(scope, order)
      
      {:update_status, %Order{} = order} -> 
        can_update_order_status?(scope, order)
      
      {:cancel, %Order{} = order} -> 
        can_cancel_order?(scope, order)
      
      # Menu item authorization
      {:update, %MenuItem{} = item} -> 
        can_update_menu_item?(scope, item)
      
      {:delete, %MenuItem{} = item} -> 
        can_delete_menu_item?(scope, item)
      
      # Default
      _ -> false
    end
  end
  
  # Order permissions
  defp can_view_order?(%Scope{type: :admin}, _order), do: true
  defp can_view_order?(%Scope{type: :cashier}, _order), do: true
  defp can_view_order?(%Scope{type: :vendor} = scope, order) do
    Scope.owns_vendor?(scope, order)
  end
  defp can_view_order?(%Scope{type: :customer} = scope, order) do
    order.customer_phone == Scope.customer_phone(scope) &&
    order.table_number == Scope.customer_table(scope)
  end
  defp can_view_order?(_, _), do: false
  
  defp can_update_order_status?(%Scope{type: :admin}, _order), do: true
  defp can_update_order_status?(%Scope{type: :vendor} = scope, order) do
    Scope.owns_vendor?(scope, order) && order.status in ["pending", "preparing"]
  end
  defp can_update_order_status?(_, _), do: false
  
  defp can_cancel_order?(%Scope{type: :admin}, _order), do: true
  defp can_cancel_order?(%Scope{type: :vendor} = scope, order) do
    Scope.owns_vendor?(scope, order) && order.status == "pending"
  end
  defp can_cancel_order?(_, _), do: false
  
  # Menu item permissions
  defp can_update_menu_item?(%Scope{type: :admin}, _item), do: true
  defp can_update_menu_item?(%Scope{type: :vendor} = scope, item) do
    Scope.owns_vendor?(scope, item)
  end
  defp can_update_menu_item?(_, _), do: false
  
  defp can_delete_menu_item?(%Scope{type: :admin}, _item), do: true
  defp can_delete_menu_item?(%Scope{type: :vendor} = scope, item) do
    Scope.owns_vendor?(scope, item)
  end
  defp can_delete_menu_item?(_, _), do: false
end
```

### Phase 3: Updated Router Configuration

```elixir
defmodule RiverSideWeb.Router do
  use RiverSideWeb, :router
  
  # ... pipelines ...
  
  # Public routes - guests can access
  scope "/", RiverSideWeb do
    pipe_through :browser
    
    live_session :public,
      on_mount: [{RiverSideWeb.UserAuth, :mount_guest_scope}] do
      live "/", TableLive.Index, :index
    end
  end
  
  # Customer routes - active customer session required
  scope "/customer", RiverSideWeb do
    pipe_through :browser
    
    live_session :customer,
      on_mount: [{RiverSideWeb.UserAuth, :mount_customer_scope}] do
      live "/checkin/:table_number", CustomerLive.Checkin, :new
      live "/menu", CustomerLive.Menu, :index
      live "/cart", CustomerLive.Cart, :index
      live "/orders", CustomerLive.OrderTracking, :index
    end
  end
  
  # Admin routes
  scope "/admin", RiverSideWeb do
    pipe_through [:browser, :require_authenticated_user]
    
    live_session :admin,
      on_mount: [{RiverSideWeb.UserAuth, :require_admin_scope}] do
      live "/dashboard", AdminLive.Dashboard, :index
      live "/vendors", AdminLive.VendorList, :index
      live "/vendors/new", AdminLive.VendorForm, :new
      live "/vendors/:id/edit", AdminLive.VendorForm, :edit
      live "/analytics", AdminLive.Analytics, :index
      live "/users", AdminLive.UserManagement, :index
    end
  end
  
  # Vendor routes
  scope "/vendor", RiverSideWeb do
    pipe_through [:browser, :require_authenticated_user]
    
    live_session :vendor,
      on_mount: [{RiverSideWeb.UserAuth, :require_vendor_scope}] do
      live "/dashboard", VendorLive.Dashboard, :index
      live "/profile/edit", VendorLive.ProfileEdit, :edit
      live "/menu", VendorLive.MenuList, :index
      live "/menu/new", VendorLive.MenuItemForm, :new
      live "/menu/:id/edit", VendorLive.MenuItemForm, :edit
      live "/analytics", VendorLive.Analytics, :index
    end
  end
  
  # Cashier routes
  scope "/cashier", RiverSideWeb do
    pipe_through [:browser, :require_authenticated_user]
    
    live_session :cashier,
      on_mount: [{RiverSideWeb.UserAuth, :require_cashier_scope}] do
      live "/dashboard", CashierLive.Dashboard, :index
      live "/payments", CashierLive.PaymentQueue, :index
      live "/transactions", CashierLive.TransactionHistory, :index
    end
  end
end
```

### Phase 4: Enhanced UserAuth Module

```elixir
defmodule RiverSideWeb.UserAuth do
  # ... existing code ...
  
  @doc "Mount guest scope for public pages"
  def on_mount(:mount_guest_scope, _params, _session, socket) do
    {:cont, assign(socket, :current_scope, Scope.for_guest())}
  end
  
  @doc "Mount customer scope from session"
  def on_mount(:mount_customer_scope, params, session, socket) do
    scope = get_customer_scope(params, session)
    
    if scope && Scope.active_customer?(scope) do
      {:cont, assign(socket, :current_scope, scope)}
    else
      {:halt, redirect_to_checkin(socket)}
    end
  end
  
  @doc "Require admin scope"
  def on_mount(:require_admin_scope, _params, session, socket) do
    socket = mount_current_scope(socket, session)
    
    if Scope.admin?(socket.assigns.current_scope) do
      {:cont, socket}
    else
      {:halt, handle_unauthorized(socket, "Admin access required")}
    end
  end
  
  @doc "Require vendor scope with preloaded vendor data"
  def on_mount(:require_vendor_scope, _params, session, socket) do
    socket = mount_current_scope(socket, session)
    scope = socket.assigns.current_scope
    
    if Scope.vendor?(scope) && scope.vendor do
      {:cont, socket}
    else
      {:halt, handle_unauthorized(socket, "Vendor access required")}
    end
  end
  
  @doc "Require cashier scope"
  def on_mount(:require_cashier_scope, _params, session, socket) do
    socket = mount_current_scope(socket, session)
    
    if Scope.cashier?(socket.assigns.current_scope) do
      {:cont, socket}
    else
      {:halt, handle_unauthorized(socket, "Cashier access required")}
    end
  end
  
  # Customer scope management
  defp get_customer_scope(params, session) do
    cond do
      # Check URL params first (for new sessions)
      params["phone"] && params["table"] ->
        Scope.for_customer(params["phone"], String.to_integer(params["table"]))
      
      # Check session for existing customer
      session["customer_phone"] && session["customer_table"] ->
        Scope.for_customer(session["customer_phone"], session["customer_table"])
      
      # No customer info
      true ->
        nil
    end
  end
  
  defp redirect_to_checkin(socket) do
    socket
    |> Phoenix.LiveView.put_flash(:info, "Please check in first")
    |> Phoenix.LiveView.redirect(to: ~p"/")
  end
  
  defp handle_unauthorized(socket, message) do
    redirect_path = case socket.assigns[:current_scope] do
      %{type: :vendor} -> ~p"/vendor/dashboard"
      %{type: :cashier} -> ~p"/cashier/dashboard"
      %{type: :admin} -> ~p"/admin/dashboard"
      %{user: nil} -> ~p"/users/log-in"
      _ -> ~p"/"
    end
    
    socket
    |> Phoenix.LiveView.put_flash(:error, message)
    |> Phoenix.LiveView.redirect(to: redirect_path)
  end
end
```

### Phase 5: Updated LiveView Implementations

#### 5.1 Vendor Dashboard with Scope

```elixir
defmodule RiverSideWeb.VendorLive.Dashboard do
  use RiverSideWeb, :live_view
  
  alias RiverSide.Vendors
  alias RiverSide.Accounts.Scope
  
  def mount(_params, _session, socket) do
    # Vendor is already loaded in scope!
    vendor = socket.assigns.current_scope.vendor
    
    if connected?(socket) do
      Vendors.subscribe_to_vendor_updates(vendor.id)
    end
    
    {:ok,
     socket
     |> assign(vendor: vendor)
     |> assign(page_title: vendor.name)
     |> load_dashboard_data()}
  end
  
  def handle_event("update_order_status", %{"order_id" => order_id, "status" => status}, socket) do
    order = Vendors.get_order!(order_id)
    
    # Use scope for authorization
    if Scope.can?(socket.assigns.current_scope, :update_status, order) do
      case Vendors.update_order_status(order, %{status: status}) do
        {:ok, _updated_order} ->
          {:noreply, 
           socket
           |> put_flash(:info, "Order status updated")
           |> load_dashboard_data()}
        
        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "Failed to update order")}
      end
    else
      {:noreply, put_flash(socket, :error, "You cannot update this order")}
    end
  end
  
  defp load_dashboard_data(socket) do
    vendor_id = socket.assigns.vendor.id
    
    socket
    |> assign(active_orders: Vendors.list_active_orders(vendor_id))
    |> assign(menu_items: Vendors.list_menu_items(vendor_id))
    |> assign(sales_stats: Vendors.get_sales_stats(vendor_id))
  end
end
```

#### 5.2 Customer Order Tracking with Scope

```elixir
defmodule RiverSideWeb.CustomerLive.OrderTracking do
  use RiverSideWeb, :live_view
  
  alias RiverSide.Vendors
  alias RiverSide.Accounts.Scope
  
  def mount(_params, _session, socket) do
    scope = socket.assigns.current_scope
    
    # Get customer info from scope
    phone = Scope.customer_phone(scope)
    table_number = Scope.customer_table(scope)
    
    orders = Vendors.list_customer_orders(phone, table_number)
    
    # Subscribe to order updates
    Enum.each(orders, fn order ->
      Vendors.subscribe_to_order_updates(order.id)
    end)
    
    {:ok,
     socket
     |> assign(orders: orders)
     |> assign(customer_info: scope.customer_info)}
  end
  
  def handle_info({:order_updated, updated_order}, socket) do
    # Check if this customer can view this order
    if Scope.can?(socket.assigns.current_scope, :view, updated_order) do
      orders = update_order_in_list(socket.assigns.orders, updated_order)
      {:noreply, assign(socket, orders: orders)}
    else
      {:noreply, socket}
    end
  end
end
```

#### 5.3 Admin Dashboard with Scope

```elixir
defmodule RiverSideWeb.AdminLive.Dashboard do
  use RiverSideWeb, :live_view
  
  alias RiverSide.{Vendors, Accounts}
  alias RiverSide.Accounts.Scope
  
  def mount(_params, _session, socket) do
    # Admin scope gives access to everything
    if connected?(socket) do
      Vendors.subscribe_to_all_orders()
    end
    
    {:ok, load_admin_data(socket)}
  end
  
  def handle_event("disable_vendor", %{"vendor_id" => vendor_id}, socket) do
    if Scope.can?(socket.assigns.current_scope, :update_vendor) do
      vendor = Vendors.get_vendor!(vendor_id)
      
      case Vendors.update_vendor(vendor, %{active: false}) do
        {:ok, _vendor} ->
          {:noreply, 
           socket
           |> put_flash(:info, "Vendor disabled")
           |> load_admin_data()}
        
        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "Failed to disable vendor")}
      end
    else
      {:noreply, put_flash(socket, :error, "Unauthorized action")}
    end
  end
  
  defp load_admin_data(socket) do
    socket
    |> assign(vendors: Vendors.list_vendors())
    |> assign(total_orders: Vendors.count_orders())
    |> assign(revenue_stats: Vendors.get_revenue_stats())
    |> assign(active_users: Accounts.count_active_users())
  end
end
```

### Phase 6: Template Updates

#### 6.1 Navigation Component

```heex
defmodule RiverSideWeb.Components.Navigation do
  use RiverSideWeb, :html
  
  alias RiverSide.Accounts.Scope
  
  attr :current_scope, :map, required: true
  
  def navbar(assigns) do
    ~H"""
    <nav class="navbar bg-base-300 shadow-lg">
      <div class="navbar-start">
        <a href="/" class="btn btn-ghost text-xl">River Side Food Court</a>
      </div>
      
      <div class="navbar-end">
        <%= if Scope.authenticated?(@current_scope) do %>
          <!-- Authenticated user menu -->
          <div class="dropdown dropdown-end">
            <label tabindex="0" class="btn btn-ghost">
              <%= @current_scope.user.name %>
              <svg class="w-4 h-4 ml-2" fill="none" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
              </svg>
            </label>
            <ul tabindex="0" class="dropdown-content menu p-2 shadow bg-base-100 rounded-box w-52">
              <%= if Scope.admin?(@current_scope) do %>
                <li><.link href={~p"/admin/dashboard"}>Admin Dashboard</.link></li>
                <li><.link href={~p"/admin/vendors"}>Manage Vendors</.link></li>
                <li><.link href={~p"/admin/analytics"}>Analytics</.link></li>
                <li class="divider"></li>
              <% end %>
              
              <%= if Scope.vendor?(@current_scope) do %>
                <li><.link href={~p"/vendor/dashboard"}>Vendor Dashboard</.link></li>
                <li><.link href={~p"/vendor/menu"}>Manage Menu</.link></li>
                <li><.link href={~p"/vendor/analytics"}>Sales Analytics</.link></li>
                <li class="divider"></li>
              <% end %>
              
              <%= if Scope.cashier?(@current_scope) do %>
                <li><.link href={~p"/cashier/dashboard"}>Cashier Dashboard</.link></li>
                <li><.link href={~p"/cashier/payments"}>Process Payments</.link></li>
                <li class="divider"></li>
              <% end %>
              
              <li><.link href={~p"/users/settings"}>Settings</.link></li>
              <li><.link href={~p"/users/log-out"} method="delete">Log Out</.link></li>
            </ul>
          </div>
        <% else %>
          <%= if Scope.customer?(@current_scope) do %>
            <!-- Customer info -->
            <div class="flex items-center gap-4">
              <span class="text-sm">
                Table #<%= @current_scope.customer_info.table_number %>
              </span>
              <.link href={~p"/"} class="btn btn-sm btn-error">End Session</.link>
            </div>
          <% else %>
            <!-- Guest -->
            <.link href={~p"/users/log-in"} class="btn btn-primary btn-sm">
              Staff Login
            </.link>
          <% end %>
        <% end %>
      </div>
    </nav>
    """
  end
end
```

#### 6.2 Authorization in Templates

```heex
<!-- In vendor dashboard -->
<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
  <%= for order <- @active_orders do %>
    <div class="card bg-base-100 shadow-xl">
      <div class="card-body">
        <h3 class="card-title">Order #<%= order.order_number %></h3>
        
        <!-- Only show actions if vendor can update this order -->
        <%= if Scope.can?(@current_scope, :update_status, order) do %>
          <div class="card-actions">
            <%= if order.status == "pending" do %>
              <button phx-click="accept_order" phx-value-id={order.id} class="btn btn-primary">
                Accept Order
              </button>
            <% end %>
            
            <%= if order.status == "preparing" do %>
              <button phx-click="mark_ready" phx-value-id={order.id} class="btn btn-success">
                Mark Ready
              </button>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
  <% end %>
</div>
```

### Phase 7: Testing Strategy

```elixir
defmodule RiverSideWeb.ScopeAuthorizationTest do
  use RiverSideWeb.ConnCase, async: true
  
  alias RiverSide.Accounts.Scope
  
  describe "scope authorization" do
    test "admin can access all areas" do
      admin = user_fixture(type: "admin")
      scope = Scope.for_user(admin)
      
      assert Scope.admin?(scope)
      assert Scope.can?(scope, :view_all_orders)
      assert Scope.can?(scope, :manage_vendors)
      assert Scope.can?(scope, :process_payments)
    end
    
    test "vendor can only manage own resources" do
      vendor_user = user_fixture(type: "vendor")
      vendor = vendor_fixture(user_id: vendor_user.id)
      scope = Scope.for_user(vendor_user)
      
      # Own menu item
      own_item = menu_item_fixture(vendor_id: vendor.id)
      assert Scope.can?(scope, :update, own_item)
      
      # Other vendor's item
      other_vendor = vendor_fixture()
      other_item = menu_item_fixture(vendor_id: other_vendor.id)
      refute Scope.can?(scope, :update, other_item)
    end
    
    test "customer can view own orders" do
      phone = "1234567890"
      table = 5
      scope = Scope.for_customer(phone, table)
      
      # Own order
      own_order = order_fixture(customer_phone: phone, table_number: table)
      assert Scope.can?(scope, :view, own_order)
      
      # Other customer's order
      other_order = order_fixture(customer_phone: "9876543210", table_number: 10)
      refute Scope.can?(scope, :view, other_order)
    end
  end
end
```

## Benefits of These Improvements

### 1. **Centralized Authorization**
- All permission logic in one place
- Easier to audit and maintain
- Consistent authorization across the app

### 2. **Performance Optimization**
- Vendor data loaded once in scope
- No repeated database queries
- Efficient permission checks

### 3. **Better Security**
- Resource-level authorization
- Clear permission boundaries
- Audit trail through scope session IDs

### 4. **Improved Developer Experience**
- Clear patterns for authorization
- Type-safe scope checks
- Better error messages

### 5. **Enhanced Customer Experience**
- Proper session management
- Automatic session expiration
- Context-aware UI

### 6. **Scalability**
- Easy to add new roles
- Simple to extend permissions
- Clean separation of concerns

## Migration Strategy

### Week 1: Foundation
1. Implement enhanced Scope module
2. Add Authorization module
3. Update UserAuth with new callbacks
4. Write comprehensive tests

### Week 2: Core Features
1. Migrate vendor dashboard to use scopes
2. Update customer session handling
3. Implement admin authorization
4. Update navigation components

### Week 3: Complete Migration
1. Update all LiveViews to use scopes
2. Remove old authorization code
3. Update all templates
4. Performance testing

### Week 4: Polish
1. Add logging and monitoring
2. Documentation updates
3. Team training
4. Deploy to production

## Monitoring and Success Metrics

### Performance Metrics
- Reduced database queries per request
- Faster page load times
- Lower memory usage

### Security Metrics
- Failed authorization attempts
- Session duration tracking
- Permission usage