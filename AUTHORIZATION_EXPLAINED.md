# Authorization Implementation in River Side Food Court

## Overview

River Side implements a **scope-based authorization system** that provides fine-grained, role-based access control for five user types: Admin, Vendor, Cashier, Customer, and Guest. The system combines two powerful modules:

1. **Scope Module** ([scope.ex:1](lib/river_side/accounts/scope.ex#L1)) - Creates and manages user context with permissions
2. **Authorization Module** ([authorization.ex:1](lib/river_side/authorization.ex#L1)) - Enforces resource-based policies

## Core Concepts

### The Scope Structure

The `Scope` is the central abstraction that represents a user's identity and permissions throughout the application:

```elixir
%Scope{
  user: %User{},              # The authenticated user (nil for customers/guests)
  role: :admin,               # One of: :admin, :vendor, :cashier, :customer, :guest
  vendor: %Vendor{},          # Preloaded vendor record (only for vendor users)
  permissions: %{},           # Map of boolean permissions
  customer_info: %{},         # Customer session data (phone, table_number)
  session_id: "...",          # Unique session identifier
  expires_at: ~U[...]         # Session expiration (for customers, 4 hours)
}
```

### Two-Layer Authorization

**Layer 1: Permission-Based** ([scope.ex:111-120](lib/river_side/accounts/scope.ex#L111-120))
- Simple boolean checks: "Can this user perform X?"
- Defined per role in permission maps
- Fast, stateless checks

**Layer 2: Resource-Based** ([authorization.ex:23-68](lib/river_side/authorization.ex#L23-68))
- Contextual checks: "Can this user perform X on this specific resource Y?"
- Ownership verification
- State-dependent logic (e.g., can only cancel pending orders)

## User Roles & Permissions

### 1. Admin ([scope.ex:219-252](lib/river_side/accounts/scope.ex#L219-252))

**Role Creation:**
```elixir
# Determined by user.is_admin flag
%Scope{role: :admin, user: %User{is_admin: true}}
```

**Permissions (God Mode):**
- ✅ **Vendor Management**: View all, create, update, delete any vendor
- ✅ **Order Management**: View all, update any, cancel any order
- ✅ **Menu Management**: Update/delete any vendor's menu items
- ✅ **Financial**: Process payments, refunds, view all transactions and analytics
- ✅ **System**: Manage users, view system logs
- ✅ **Dashboard Access**: Admin, vendor, and cashier dashboards

**Authorization Logic:**
```elixir
# Admins bypass most resource checks
defp can_update_order?(%Scope{role: :admin}, _order), do: true
defp can_delete_vendor?(%Scope{role: :admin}, _vendor), do: true
```

**Use Cases:**
- Platform owner/operator
- System administrator
- Full oversight and control

---

### 2. Vendor ([scope.ex:254-277](lib/river_side/accounts/scope.ex#L254-277))

**Role Creation:**
```elixir
# Determined by user.is_vendor flag + vendor record preloading
scope = %Scope{
  role: :vendor,
  user: %User{is_vendor: true},
  vendor: %Vendor{id: 123, name: "Burger Stand"}  # Auto-loaded!
}
```

**Key Feature: Automatic Vendor Context Loading** ([scope.ex:191-196](lib/river_side/accounts/scope.ex#L191-196))
```elixir
defp load_vendor_context(%__MODULE__{role: :vendor, user: %{id: user_id}} = scope) do
  case Vendors.get_vendor_by_user_id(user_id) do
    %Vendor{} = vendor -> %{scope | vendor: vendor}
    nil -> scope
  end
end
```

**Permissions (Own Resources Only):**
- ✅ **Menu Management**: Create, view, update, delete own menu items
- ✅ **Order Management**: View own orders, update status, cancel pending orders
- ✅ **Analytics**: View own sales data and transactions
- ✅ **Profile**: Update own vendor profile
- ❌ Cannot access other vendors' data
- ❌ Cannot process payments

**Authorization Logic - Ownership Checks** ([authorization.ex:96-101](lib/river_side/authorization.ex#L96-101)):
```elixir
defp can_update_order_status?(
  %Scope{role: :vendor} = scope,
  %Order{vendor_id: vendor_id, status: status}
) do
  # Must own the vendor AND order must be in modifiable state
  Scope.owns_vendor?(scope, vendor_id) && status in ["pending", "preparing"]
end
```

**Ownership Verification** ([scope.ex:145-156](lib/river_side/accounts/scope.ex#L145-156)):
```elixir
def owns_vendor?(%__MODULE__{role: :vendor, vendor: %{id: vendor_id}}, check_vendor_id) do
  vendor_id == check_vendor_id
end

# Admins "own" everything
def owns_vendor?(%__MODULE__{role: :admin}, _), do: true
```

**Query Scoping** ([authorization.ex:211-219](lib/river_side/authorization.ex#L211-219)):
```elixir
{:vendor, :orders} ->
  # Automatically filter queries to vendor's orders only
  import Ecto.Query
  where(query, [o], o.vendor_id == ^Scope.vendor_id(scope))
```

**Use Cases:**
- Individual food stall operator
- Manage their menu and orders
- Track their sales performance

---

### 3. Cashier ([scope.ex:279-295](lib/river_side/accounts/scope.ex#L279-295))

**Role Creation:**
```elixir
%Scope{role: :cashier, user: %User{is_cashier: true}}
```

**Permissions (Payment-Focused):**
- ✅ **Payment Processing**: Process payments, mark orders as paid, handle refunds
- ✅ **Order Viewing**: View all orders (read-only), view details
- ✅ **Dashboard**: Access cashier dashboard, view daily transactions
- ❌ Cannot modify order status
- ❌ Cannot manage menus or vendors

**Authorization Logic** ([authorization.ex:116-118](lib/river_side/authorization.ex#L116-118)):
```elixir
defp can_mark_order_paid?(%Scope{role: :admin}, _order), do: true
defp can_mark_order_paid?(%Scope{role: :cashier}, _order), do: true
defp can_mark_order_paid?(_, _), do: false
```

**Cross-Vendor Access:**
Cashiers can view and process payments for ALL vendors' orders:
```elixir
defp can_view_order?(%Scope{role: :cashier}, _order), do: true
```

**Use Cases:**
- Centralized payment counter
- Process customer payments
- Handle refunds

---

### 4. Customer ([scope.ex:297-309](lib/river_side/accounts/scope.ex#L297-309))

**Role Creation (Sessionless Auth)** ([scope.ex:58-71](lib/river_side/accounts/scope.ex#L58-71)):
```elixir
def for_customer(phone, table_number) do
  %__MODULE__{
    user: nil,  # No user account!
    role: :customer,
    customer_info: %{
      phone: phone,
      table_number: table_number,
      session_started: DateTime.utc_now()
    },
    permissions: customer_permissions(),
    session_id: generate_session_id(),
    expires_at: DateTime.add(DateTime.utc_now(), 4, :hour)  # 4-hour session
  }
end
```

**Unique Features:**
- **No User Account Required**: Identified by phone + table number
- **Time-Limited Sessions**: Auto-expires after 4 hours ([scope.ex:160-164](lib/river_side/accounts/scope.ex#L160-164))
- **Table-Based Ordering**: Tied to physical table location

**Permissions (Ordering Only):**
- ✅ **Menu & Ordering**: View menu, place orders, track own orders
- ✅ **Cart Management**: Manage cart, checkout
- ❌ Cannot view other customers' orders
- ❌ Cannot modify order status
- ❌ No dashboard access

**Authorization Logic - Session & Table Matching** ([authorization.ex:79-82](lib/river_side/authorization.ex#L79-82)):
```elixir
defp can_view_order?(%Scope{role: :customer} = scope, %Order{} = order) do
  # Must match BOTH phone and table number
  order.customer_name == Scope.customer_phone(scope) &&
    order.table_number == to_string(Scope.customer_table(scope))
end
```

**Session Validation** ([scope.ex:160-164](lib/river_side/accounts/scope.ex#L160-164)):
```elixir
def active_customer?(%__MODULE__{role: :customer, expires_at: expires_at}) do
  DateTime.compare(expires_at, DateTime.utc_now()) == :gt
end
```

**Use Cases:**
- Dine-in customers
- Quick ordering without account creation
- Table-specific orders

---

### 5. Guest ([scope.ex:311-316](lib/river_side/accounts/scope.ex#L311-316))

**Role Creation** ([scope.ex:76-83](lib/river_side/accounts/scope.ex#L76-83)):
```elixir
def for_guest do
  %__MODULE__{
    user: nil,
    role: :guest,
    permissions: guest_permissions(),
    session_id: generate_session_id()
  }
end
```

**Permissions (Browse Only):**
- ✅ **View Menu**: Browse available food items
- ✅ **View Table Availability**: Check which tables are available
- ❌ Cannot place orders
- ❌ Cannot access any dashboards

**Use Cases:**
- Browsing the menu before check-in
- Checking table availability
- Landing page visitors

---

## Authorization Flow

### 1. Scope Creation

**During Login** ([scope.ex:38-49](lib/river_side/accounts/scope.ex#L38-49)):
```elixir
def for_user(%User{} = user) do
  base_scope = %__MODULE__{
    user: user,
    role: determine_role(user),           # Step 1: Determine role from flags
    session_id: generate_session_id(),
    expires_at: nil
  }

  base_scope
  |> load_vendor_context()                # Step 2: Load vendor if applicable
  |> assign_permissions()                 # Step 3: Assign role-based permissions
end
```

**Role Determination** ([scope.ex:182-189](lib/river_side/accounts/scope.ex#L182-189)):
```elixir
defp determine_role(%User{} = user) do
  cond do
    user.is_admin -> :admin      # Priority order matters!
    user.is_vendor -> :vendor
    user.is_cashier -> :cashier
    true -> :guest
  end
end
```

### 2. Permission Assignment

**Automatic Role-Based Mapping** ([scope.ex:200-211](lib/river_side/accounts/scope.ex#L200-211)):
```elixir
defp assign_permissions(%__MODULE__{role: role} = scope) do
  permissions =
    case role do
      :admin -> admin_permissions()      # 18 permissions
      :vendor -> vendor_permissions()    # 9 permissions
      :cashier -> cashier_permissions()  # 7 permissions
      :customer -> customer_permissions() # 6 permissions
      _ -> guest_permissions()           # 2 permissions
    end

  %{scope | permissions: permissions}
end
```

### 3. Authorization Checks

**Two-Arity: Simple Permission Check** ([scope.ex:111-115](lib/river_side/accounts/scope.ex#L111-115)):
```elixir
Scope.can?(scope, :manage_menu)
# Looks up permissions map
# Returns true/false
```

**Three-Arity: Resource-Based Check** ([scope.ex:118-120](lib/river_side/accounts/scope.ex#L118-120)):
```elixir
Scope.can?(scope, :update, menu_item)
# Delegates to Authorization module
# Checks ownership and state
```

### 4. Resource Authorization

**Pattern Matching on Action + Resource** ([authorization.ex:23-68](lib/river_side/authorization.ex#L23-68)):
```elixir
def check(%Scope{} = scope, action, resource) do
  case {action, resource} do
    {:view, %Order{} = order} ->
      can_view_order?(scope, order)        # Role + ownership check

    {:update_status, %Order{} = order} ->
      can_update_order_status?(scope, order)  # Role + ownership + state check

    {:delete, %Vendor{} = vendor} ->
      can_delete_vendor?(scope, vendor)    # Role check only (admin-only)

    _ ->
      false  # Default deny for unknown actions
  end
end
```

### 5. Query Scoping

**Automatic Data Filtering** ([authorization.ex:205-237](lib/river_side/authorization.ex#L205-237)):
```elixir
def scope_query(%Scope{} = scope, query, resource_type) do
  case {scope.role, resource_type} do
    {:admin, _} ->
      query  # No filtering

    {:vendor, :orders} ->
      where(query, [o], o.vendor_id == ^Scope.vendor_id(scope))

    {:customer, :orders} ->
      phone = Scope.customer_phone(scope)
      table = to_string(Scope.customer_table(scope))
      where(query, [o], o.customer_name == ^phone and o.table_number == ^table)

    _ ->
      where(query, [_], false)  # No access
  end
end
```

**Usage in Context Modules:**
```elixir
Order
|> Authorization.scope_query(scope, :orders)
|> Repo.all()
# Returns only orders the scope can access
```

---

## State-Dependent Authorization

Some actions require checking the **current state** of a resource, not just ownership.

### Order Status Transitions

**Vendor Order Status Updates** ([authorization.ex:94-103](lib/river_side/authorization.ex#L94-103)):
```elixir
defp can_update_order_status?(
  %Scope{role: :vendor} = scope,
  %Order{vendor_id: vendor_id, status: status}
) do
  # Vendor can only update if:
  # 1. They own the order
  # 2. Order is still pending or preparing (not completed/paid)
  Scope.owns_vendor?(scope, vendor_id) && status in ["pending", "preparing"]
end
```

**Vendor Order Cancellation** ([authorization.ex:107-112](lib/river_side/authorization.ex#L107-112)):
```elixir
defp can_cancel_order?(
  %Scope{role: :vendor} = scope,
  %Order{vendor_id: vendor_id, status: "pending"}
) do
  # Can only cancel if order is still pending
  Scope.owns_vendor?(scope, vendor_id)
end
```

**Authorization Flow:**
```
Vendor attempts to cancel order
  ↓
Check role: ✓ Vendor
  ↓
Check ownership: ✓ order.vendor_id == scope.vendor.id
  ↓
Check state: ✗ status == "completed"
  ↓
DENIED: Cannot cancel completed orders
```

---

## Convenience Helpers

### Role Checks ([scope.ex:86-108](lib/river_side/accounts/scope.ex#L86-108))

```elixir
Scope.admin?(scope)           # true if admin
Scope.vendor?(scope)          # true if vendor
Scope.cashier?(scope)         # true if cashier
Scope.customer?(scope)        # true if customer
Scope.guest?(scope)           # true if guest
Scope.authenticated?(scope)   # true if has user account
```

### Permission Checks ([scope.ex:123-141](lib/river_side/accounts/scope.ex#L123-141))

```elixir
Scope.can_manage_orders?(scope)
Scope.can_process_payments?(scope)
Scope.can_manage_menu?(scope)
Scope.can_view_all_vendors?(scope)
Scope.can_manage_vendors?(scope)
```

### Vendor Helpers ([scope.ex:176-178](lib/river_side/accounts/scope.ex#L176-178))

```elixir
Scope.vendor_id(scope)        # Get vendor ID from scope
Scope.owns_vendor?(scope, 5)  # Check if scope owns vendor ID 5
```

### Customer Helpers ([scope.ex:166-174](lib/river_side/accounts/scope.ex#L166-174))

```elixir
Scope.customer_phone(scope)   # Get customer phone
Scope.customer_table(scope)   # Get customer table number
Scope.active_customer?(scope) # Check if session is valid
```

---

## Usage in LiveView

### Mount Callbacks

Every LiveView receives `@current_scope` automatically via mount hooks:

```elixir
defmodule RiverSideWeb.VendorLive.Dashboard do
  use RiverSideWeb, :live_view

  def mount(_params, _session, socket) do
    scope = socket.assigns.current_scope

    # Check role
    if Scope.vendor?(scope) do
      # Access preloaded vendor
      vendor_name = scope.vendor.name
      vendor_id = Scope.vendor_id(scope)

      {:ok, assign(socket, vendor_name: vendor_name)}
    else
      {:ok, redirect(socket, to: "/")}
    end
  end
end
```

### Event Handlers

```elixir
def handle_event("update_menu_item", %{"id" => id} = params, socket) do
  scope = socket.assigns.current_scope
  menu_item = Vendors.get_menu_item!(id)

  # Check resource-based permission
  if Scope.can?(scope, :update, menu_item) do
    case Vendors.update_menu_item(menu_item, params) do
      {:ok, updated_item} ->
        {:noreply, socket |> put_flash(:info, "Updated!")}
      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  else
    {:noreply, put_flash(socket, :error, "Not authorized")}
  end
end
```

### Loading Scoped Data

```elixir
def mount(_params, _session, socket) do
  scope = socket.assigns.current_scope

  # Query is automatically filtered by Authorization.scope_query
  orders =
    Order
    |> Authorization.scope_query(scope, :orders)
    |> order_by([o], desc: o.inserted_at)
    |> Repo.all()

  {:ok, assign(socket, orders: orders)}
end
```

---

## Security Principles

### 1. Default Deny

Unknown actions are denied by default:
```elixir
def check(%Scope{} = scope, action, resource) do
  case {action, resource} do
    # ... explicit patterns ...
    _ -> false  # Deny everything else
  end
end
```

### 2. Explicit Permissions

Every permission must be explicitly granted in the role's permission map.

### 3. Layered Checks

Multiple layers of authorization:
1. **Route level**: `on_mount` callbacks block unauthorized access
2. **Permission level**: `can?/2` checks role permissions
3. **Resource level**: `can?/3` checks ownership and state
4. **Query level**: `scope_query/3` filters database queries

### 4. Ownership Verification

Resources are checked for ownership, not just role:
```elixir
# Not enough to be a vendor
# Must be THE vendor who owns the resource
Scope.owns_vendor?(scope, menu_item.vendor_id)
```

### 5. Immutable Scopes

Scopes are created once per session and not modified during requests, preventing tampering.

---

## Authorization Decision Matrix

| Action | Admin | Vendor (Own) | Vendor (Other) | Cashier | Customer (Own) | Guest |
|--------|-------|--------------|----------------|---------|----------------|-------|
| **View order** | ✅ | ✅ | ❌ | ✅ | ✅ | ❌ |
| **Update order status** | ✅ | ✅ (if pending/preparing) | ❌ | ❌ | ❌ | ❌ |
| **Cancel order** | ✅ | ✅ (if pending) | ❌ | ❌ | ❌ | ❌ |
| **Mark order paid** | ✅ | ❌ | ❌ | ✅ | ❌ | ❌ |
| **View menu item** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Create menu item** | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| **Update menu item** | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| **Delete menu item** | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| **View vendor** | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| **Update vendor** | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| **Delete vendor** | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **Process payments** | ✅ | ❌ | ❌ | ✅ | ❌ | ❌ |
| **View analytics** | ✅ (all) | ✅ (own) | ❌ | ✅ (daily) | ❌ | ❌ |

---

## Error Handling

### User-Friendly Messages ([authorization.ex:242-251](lib/river_side/authorization.ex#L242-251))

```elixir
def error_message(action, resource_type) do
  case {action, resource_type} do
    {:view, :order} -> "You don't have permission to view this order"
    {:update, :order} -> "You don't have permission to update this order"
    {:cancel, :order} -> "You don't have permission to cancel this order"
    {:update, :menu_item} -> "You don't have permission to update this menu item"
    {:delete, :menu_item} -> "You don't have permission to delete this menu item"
    _ -> "You don't have permission to perform this action"
  end
end
```

### Usage in LiveView

```elixir
def handle_event("delete_item", %{"id" => id}, socket) do
  scope = socket.assigns.current_scope
  item = Vendors.get_menu_item!(id)

  case Scope.can?(scope, :delete, item) do
    true ->
      Vendors.delete_menu_item(item)
      {:noreply, put_flash(socket, :info, "Deleted!")}

    false ->
      error_msg = Authorization.error_message(:delete, :menu_item)
      {:noreply, put_flash(socket, :error, error_msg)}
  end
end
```

---

## Key Takeaways

1. **Scope is King**: Everything revolves around the scope struct containing user context
2. **Two Permission Types**: Boolean permissions (can_X?) vs. resource permissions (can_X_Y?)
3. **Automatic Context Loading**: Vendor records are preloaded for vendor users
4. **State Matters**: Some actions depend on resource state (e.g., order status)
5. **Query Scoping**: Database queries are automatically filtered by role
6. **Customer Sessions**: Customers use phone + table instead of user accounts
7. **Default Deny**: Unknown actions are denied automatically
8. **Layered Security**: Route → Permission → Resource → Query checks

This scope-based architecture ensures that every action in the River Side application is properly authorized based on the user's role, ownership of resources, and current state of the system.
