# River Side Food Court - Immediate Scope Implementation Steps

## Quick Win Improvements (Can be done in 1-2 days)

### Step 1: Enhance the Scope Module (2 hours)

Update `lib/river_side/accounts/scope.ex`:

```elixir
defmodule RiverSide.Accounts.Scope do
  @moduledoc """
  Enhanced scope for River Side's multi-role system.
  Quick win: Add role detection and vendor preloading.
  """
  
  alias RiverSide.Accounts.User
  alias RiverSide.Vendors
  
  defstruct [:user, :role, :vendor]
  
  def for_user(%User{} = user) do
    %__MODULE__{
      user: user,
      role: determine_role(user),
      vendor: load_vendor_for_user(user)
    }
  end
  
  def for_user(nil), do: %__MODULE__{user: nil, role: :guest}
  
  # Add role helpers
  def admin?(%__MODULE__{role: :admin}), do: true
  def admin?(_), do: false
  
  def vendor?(%__MODULE__{role: :vendor}), do: true
  def vendor?(_), do: false
  
  def cashier?(%__MODULE__{role: :cashier}), do: true
  def cashier?(_), do: false
  
  def authenticated?(%__MODULE__{user: nil}), do: false
  def authenticated?(%__MODULE__{user: _}), do: true
  
  # Private functions
  defp determine_role(%User{type: type}) do
    case type do
      "admin" -> :admin
      "vendor" -> :vendor
      "cashier" -> :cashier
      _ -> :user
    end
  end
  
  defp determine_role(_), do: :guest
  
  defp load_vendor_for_user(%User{type: "vendor", id: user_id}) do
    Vendors.get_vendor_by_user_id(user_id)
  end
  defp load_vendor_for_user(_), do: nil
end
```

### Step 2: Update Vendor Dashboard (1 hour)

Modify `lib/river_side_web/live/vendor_live/dashboard.ex`:

```elixir
def mount(_params, _session, socket) do
  # OLD CODE:
  # user = socket.assigns.current_user
  # vendor = Vendors.get_vendor_by_user_id(user.id)
  
  # NEW CODE - vendor is already in scope!
  vendor = socket.assigns.current_scope.vendor
  
  if vendor do
    if connected?(socket) do
      Vendors.subscribe_to_vendor_updates(vendor.id)
    end
    
    {:ok,
     socket
     |> assign(vendor: vendor)
     |> load_vendor_data()}
  else
    # Handle case where vendor profile doesn't exist
    {:ok, create_vendor_profile(socket)}
  end
end
```

### Step 3: Add Role-Based Navigation (1 hour)

Create a new component in `lib/river_side_web/components/core_components.ex`:

```elixir
def role_based_nav(assigns) do
  ~H"""
  <div class="flex gap-2">
    <%= if RiverSide.Accounts.Scope.admin?(@current_scope) do %>
      <.link href={~p"/admin/dashboard"} class="btn btn-primary btn-sm">
        Admin Dashboard
      </.link>
    <% end %>
    
    <%= if RiverSide.Accounts.Scope.vendor?(@current_scope) do %>
      <.link href={~p"/vendor/dashboard"} class="btn btn-primary btn-sm">
        Vendor Dashboard
      </.link>
    <% end %>
    
    <%= if RiverSide.Accounts.Scope.cashier?(@current_scope) do %>
      <.link href={~p"/cashier/dashboard"} class="btn btn-primary btn-sm">
        Cashier Dashboard
      </.link>
    <% end %>
  </div>
  """
end
```

### Step 4: Add Customer Scope Support (2 hours)

Update `lib/river_side/accounts/scope.ex` to add customer support:

```elixir
# Add to the struct definition
defstruct [:user, :role, :vendor, :customer_info]

# Add new function for customer sessions
def for_customer(phone, table_number) do
  %__MODULE__{
    user: nil,
    role: :customer,
    customer_info: %{
      phone: phone,
      table_number: table_number,
      session_started: DateTime.utc_now()
    }
  }
end

# Add customer helpers
def customer?(%__MODULE__{role: :customer}), do: true
def customer?(_), do: false

def customer_phone(%__MODULE__{role: :customer, customer_info: %{phone: phone}}), do: phone
def customer_phone(_), do: nil

def customer_table(%__MODULE__{role: :customer, customer_info: %{table_number: table}}), do: table
def customer_table(_), do: nil
```

Update customer checkin to use scope:

```elixir
# In lib/river_side_web/live/customer_live/checkin.ex
def handle_event("submit", %{"phone" => phone}, socket) do
  table_number = socket.assigns.table_number
  
  # Create customer scope
  customer_scope = RiverSide.Accounts.Scope.for_customer(phone, table_number)
  
  # Store in session
  {:noreply,
   socket
   |> put_session(:customer_phone, phone)
   |> put_session(:customer_table, table_number)
   |> push_navigate(to: ~p"/customer/menu?phone=#{phone}&table=#{table_number}")}
end
```

### Step 5: Simple Permission Checks (1 hour)

Add basic permission checking to Scope:

```elixir
# In lib/river_side/accounts/scope.ex
def can_manage_orders?(%__MODULE__{role: role}) when role in [:admin, :vendor], do: true
def can_manage_orders?(_), do: false

def can_process_payments?(%__MODULE__{role: role}) when role in [:admin, :cashier], do: true
def can_process_payments?(_), do: false

def can_manage_menu?(%__MODULE__{role: role}) when role in [:admin, :vendor], do: true
def can_manage_menu?(_), do: false

def can_view_all_vendors?(%__MODULE__{role: :admin}), do: true
def can_view_all_vendors?(_), do: false

# For vendor-specific checks
def owns_vendor?(%__MODULE__{role: :vendor, vendor: %{id: vendor_id}}, check_vendor_id) do
  vendor_id == check_vendor_id
end
def owns_vendor?(%__MODULE__{role: :admin}, _), do: true
def owns_vendor?(_, _), do: false
```

Use in templates:

```heex
<!-- In vendor dashboard -->
<%= if RiverSide.Accounts.Scope.can_manage_menu?(@current_scope) do %>
  <.link href={~p"/vendor/menu/new"} class="btn btn-primary">
    Add Menu Item
  </.link>
<% end %>

<!-- In order management -->
<%= if RiverSide.Accounts.Scope.can_manage_orders?(@current_scope) do %>
  <button phx-click="update_status" phx-value-id={order.id}>
    Update Status
  </button>
<% end %>
```

## Testing Your Changes

### 1. Test Enhanced Scope
```elixir
# In test/river_side/accounts/scope_test.exs
defmodule RiverSide.Accounts.ScopeTest do
  use RiverSide.DataCase
  
  alias RiverSide.Accounts.Scope
  
  test "creates proper scope for vendor user" do
    vendor_user = user_fixture(type: "vendor")
    vendor = vendor_fixture(user_id: vendor_user.id)
    
    scope = Scope.for_user(vendor_user)
    
    assert scope.role == :vendor
    assert scope.vendor.id == vendor.id
    assert Scope.vendor?(scope)
    assert Scope.can_manage_menu?(scope)
  end
  
  test "creates proper scope for admin user" do
    admin_user = user_fixture(type: "admin")
    scope = Scope.for_user(admin_user)
    
    assert scope.role == :admin
    assert Scope.admin?(scope)
    assert Scope.can_view_all_vendors?(scope)
  end
  
  test "creates customer scope" do
    scope = Scope.for_customer("1234567890", 5)
    
    assert scope.role == :customer
    assert Scope.customer?(scope)
    assert Scope.customer_phone(scope) == "1234567890"
    assert Scope.customer_table(scope) == 5
  end
end
```

### 2. Test Vendor Dashboard
```elixir
# In test/river_side_web/live/vendor_live/dashboard_test.exs
test "vendor dashboard loads vendor from scope", %{conn: conn} do
  vendor_user = user_fixture(type: "vendor")
  vendor = vendor_fixture(user_id: vendor_user.id)
  
  conn = log_in_user(conn, vendor_user)
  {:ok, view, html} = live(conn, ~p"/vendor/dashboard")
  
  # Vendor name should appear (loaded from scope)
  assert html =~ vendor.name
  
  # Should not make additional vendor queries
  # (vendor was preloaded in scope)
end
```

## Performance Benefits

### Before (Multiple Queries):
```
[debug] QUERY OK source="users" db=2.1ms
[debug] QUERY OK source="vendors" db=1.8ms  
[debug] QUERY OK source="vendors" db=1.9ms  # Duplicate!
```

### After (Single Query):
```
[debug] QUERY OK source="users" db=2.1ms
[debug] QUERY OK source="vendors" db=1.8ms  # Loaded once in scope
```

## Next Steps

Once these quick wins are implemented:

1. **Add Authorization Module** (Week 2)
   - Create `lib/river_side/authorization.ex`
   - Implement resource-based checks
   - Add audit logging

2. **Enhance Router Configuration** (Week 2)
   - Add role-specific live_sessions
   - Implement proper on_mount callbacks
   - Add permission-based redirects

3. **Update All LiveViews** (Week 3)
   - Migrate from current_user to current_scope
   - Remove duplicate authorization logic
   - Add consistent permission checks

4. **Add Monitoring** (Week 4)
   - Track authorization failures
   - Monitor session durations
   - Add performance metrics

## Common Patterns After Implementation

### 1. In LiveView Mount
```elixir
def mount(_params, _session, socket) do
  scope = socket.assigns.current_scope
  
  # Role-based logic
  case scope.role do
    :vendor -> load_vendor_view(socket, scope.vendor)
    :admin -> load_admin_view(socket)
    :customer -> load_customer_view(socket, scope.customer_info)
    _ -> {:ok, redirect(socket, to: ~p"/")}
  end
end
```

### 2. In Event Handlers
```elixir
def handle_event("delete_item", %{"id" => id}, socket) do
  item = Vendors.get_menu_item!(id)
  
  if Scope.owns_vendor?(socket.assigns.current_scope, item.vendor_id) do
    # Proceed with deletion
  else
    {:noreply, put_flash(socket, :error, "Unauthorized")}
  end
end
```

### 3. In Templates
```heex
<div class="user-info">
  <%= case @current_scope.role do %>
    <% :admin -> %>
      <span class="badge badge-error">Admin</span>
    <% :vendor -> %>
      <span class="badge badge-primary"><%= @current_scope.vendor.name %></span>
    <% :customer -> %>
      <span class="badge badge-info">Table <%= @current_scope.customer_info.table_number %></span>
    <% _ -> %>
      <span>Guest</span>
  <% end %>
</div>
```

This implementation plan provides immediate value while setting the foundation for more comprehensive improvements later.