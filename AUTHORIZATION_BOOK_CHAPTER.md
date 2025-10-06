# Chapter 7: Building a Scope-Based Authorization System

## Introduction

In the world of multi-tenant applications, particularly in the food service industry, authorization goes far beyond a simple "logged in or not" check. When you're managing a food court with multiple vendors, cashiers, and customers—all with different needs and permissions—you need an authorization system that is both robust and intuitive.

In this chapter, we'll explore River Side's **scope-based authorization system**, a two-layer architecture that combines role-based permissions with resource-level ownership checks. You'll learn not just *what* the system does, but *why* it's designed this way, and most importantly, *how* to work with it through hands-on examples in the Elixir interactive shell.

### What You'll Learn

- The philosophy behind scope-based authorization
- How to create and manipulate scopes for different user types
- Permission checking at multiple levels
- Resource ownership verification
- Query scoping for automatic data filtering
- State-dependent authorization rules
- Real-world testing and debugging techniques

### Prerequisites

This chapter assumes you have:
- A working River Side development environment
- Basic understanding of Elixir pattern matching and structs
- Familiarity with Ecto and Phoenix LiveView
- Access to `iex -S mix` shell

---

## Part 1: The Philosophy - Why Scopes?

### The Problem Space

Imagine you're building a food court management system. You have five distinct types of users:

1. **Admins** - The platform owners who need complete control
2. **Vendors** - Individual food stall operators managing their own menus
3. **Cashiers** - Staff processing payments across all vendors
4. **Customers** - Diners placing orders from their tables
5. **Guests** - Visitors browsing menus before checking in

Each user type has different needs:

```
Admin thinks:     "I need to see everything and fix problems"
Vendor thinks:    "I only care about MY menu and MY orders"
Cashier thinks:   "I need to process payments for ALL vendors"
Customer thinks:  "I want to order from Table 5 with my phone"
Guest thinks:     "Let me see what's available before I sit down"
```

### The Traditional Approach (And Why It Fails)

You might be tempted to use a simple role-based system:

```elixir
def can_view_order?(user, order) do
  cond do
    user.role == "admin" -> true
    user.role == "vendor" -> true
    user.role == "cashier" -> true
    true -> false
  end
end
```

**Problems with this approach:**

1. ❌ **No ownership checks** - Any vendor can see any other vendor's orders
2. ❌ **Scattered logic** - Authorization code duplicated everywhere
3. ❌ **No context** - How do we handle customers without user accounts?
4. ❌ **Poor testability** - Hard to test all permission combinations
5. ❌ **State ignored** - Can't handle "vendor can cancel only pending orders"

### The Scope Solution

A **scope** is a struct that encapsulates:

- **Identity** - Who the user is (or customer/guest context)
- **Role** - Their functional role in the system
- **Context** - Related data they might need (like their vendor record)
- **Permissions** - A map of boolean capabilities
- **Ownership helpers** - Methods to verify resource ownership

This single abstraction travels through your entire request lifecycle, providing a consistent way to answer: *"What can this entity do?"*

---

## Part 2: Hands-On - The Scope Structure

Let's dive into the interactive shell to explore scopes. Fire up your development server:

```bash
cd /path/to/river_side
iex -S mix
```

### Example 1: Creating an Admin Scope

First, let's create a user and see how a scope is built:

```elixir
# Create an admin user
iex> alias RiverSide.Accounts
iex> alias RiverSide.Accounts.{User, Scope}
iex> alias RiverSide.Repo

# Create a test admin user
iex> admin_user = %User{
...>   email: "admin@foodcourt.com",
...>   is_admin: true,
...>   is_vendor: false,
...>   is_cashier: false,
...>   confirmed_at: DateTime.utc_now()
...> } |> Repo.insert!()

# Generate a scope for this admin
iex> admin_scope = Scope.for_user(admin_user)
```

**What you'll see:**

```elixir
%RiverSide.Accounts.Scope{
  user: %RiverSide.Accounts.User{
    id: 1,
    email: "admin@foodcourt.com",
    is_admin: true,
    # ... other fields
  },
  role: :admin,
  vendor: nil,
  permissions: %{
    view_all_orders: true,
    manage_orders: true,
    process_payments: true,
    # ... 15 more permissions
  },
  customer_info: %{},
  session_id: "abc123...",
  expires_at: nil
}
```

**Key observations:**

1. The `role` is automatically determined from user flags
2. `permissions` map is populated based on the role
3. `vendor` is nil (admins aren't vendors)
4. `expires_at` is nil (user accounts don't expire)

### Example 2: Role Checking

Now let's use the scope to check roles:

```elixir
iex> Scope.admin?(admin_scope)
true

iex> Scope.vendor?(admin_scope)
false

iex> Scope.authenticated?(admin_scope)
true

iex> Scope.guest?(admin_scope)
false
```

**Try this:** Create a guest scope and compare:

```elixir
iex> guest_scope = Scope.for_guest()

iex> Scope.guest?(guest_scope)
true

iex> Scope.authenticated?(guest_scope)
false

iex> guest_scope.user
nil
```

**Insight:** Notice how guests have no user account, but the system still treats them as a valid scope with limited permissions.

### Example 3: Permission Checking

Let's explore the two-arity permission check:

```elixir
# Admin permissions
iex> Scope.can?(admin_scope, :manage_vendors)
true

iex> Scope.can?(admin_scope, :manage_menu)
true

iex> Scope.can?(admin_scope, :process_payments)
true

# Guest permissions
iex> Scope.can?(guest_scope, :manage_vendors)
false

iex> Scope.can?(guest_scope, :view_menu)
true  # Guests can browse the menu
```

**What's happening here?**

The `can?/2` function simply looks up the permission in the scope's `permissions` map:

```elixir
# Look inside the permissions map
iex> admin_scope.permissions.manage_vendors
true

iex> guest_scope.permissions.manage_vendors
nil  # nil is treated as false
```

---

## Part 3: Vendor Scopes - The Context Loading Magic

Vendors are special because they need quick access to their vendor record. Let's see the "magic" in action.

### Example 4: Creating a Vendor Scope

```elixir
# Create a vendor user
iex> alias RiverSide.Vendors
iex> alias RiverSide.Vendors.Vendor

iex> vendor_user = %User{
...>   email: "burgers@foodcourt.com",
...>   is_admin: false,
...>   is_vendor: true,
...>   is_cashier: false,
...>   confirmed_at: DateTime.utc_now()
...> } |> Repo.insert!()

# Create the vendor record
iex> vendor = %Vendor{
...>   user_id: vendor_user.id,
...>   name: "Bob's Burger Stand",
...>   description: "Best burgers in town",
...>   location: "Stall A1",
...>   status: "active"
...> } |> Repo.insert!()

# Now create the scope
iex> vendor_scope = Scope.for_user(vendor_user)
```

**Observe the output:**

```elixir
%RiverSide.Accounts.Scope{
  user: %RiverSide.Accounts.User{
    id: 2,
    email: "burgers@foodcourt.com",
    is_vendor: true,
    # ...
  },
  role: :vendor,
  vendor: %RiverSide.Vendors.Vendor{
    id: 1,
    name: "Bob's Burger Stand",
    user_id: 2,
    # ...
  },  # 👈 AUTOMATICALLY LOADED!
  permissions: %{
    manage_menu: true,
    manage_own_orders: true,
    view_own_analytics: true,
    # ... 6 more vendor permissions
  },
  # ...
}
```

**The Magic Explained:**

When `Scope.for_user/1` detects a vendor role, it automatically:

1. Queries the database for the vendor record
2. Preloads it into `scope.vendor`
3. Makes it instantly available throughout the request

This means in your LiveView code, you never have to manually fetch the vendor:

```elixir
def mount(_params, _session, socket) do
  vendor_id = socket.assigns.current_scope.vendor.id  # Always available!
  vendor_name = socket.assigns.current_scope.vendor.name

  {:ok, assign(socket, vendor_id: vendor_id, vendor_name: vendor_name)}
end
```

### Example 5: Vendor Ownership Checks

The real power comes with ownership verification:

```elixir
# Check ownership of their own vendor
iex> Scope.owns_vendor?(vendor_scope, vendor.id)
true

# Check ownership of a different vendor
iex> Scope.owns_vendor?(vendor_scope, 999)
false

# Admins "own" everything
iex> Scope.owns_vendor?(admin_scope, 999)
true
```

**Use the helper:**

```elixir
# Get vendor ID directly
iex> Scope.vendor_id(vendor_scope)
1

# This is equivalent to:
iex> vendor_scope.vendor.id
1
```

---

## Part 4: Resource-Based Authorization

Now we get to the heart of the system: checking permissions on specific resources.

### Example 6: Creating Test Data

Let's set up some menu items and orders:

```elixir
# Create a menu item for our vendor
iex> alias RiverSide.Vendors.MenuItem

iex> burger = %MenuItem{
...>   vendor_id: vendor.id,
...>   name: "Classic Burger",
...>   description: "Beef patty with lettuce, tomato",
...>   price: Decimal.new("8.99"),
...>   available: true
...> } |> Repo.insert!()

# Create a menu item for a different vendor (simulate)
iex> other_vendor = %Vendor{
...>   user_id: nil,  # No user for simplicity
...>   name: "Pizza Place",
...>   description: "Italian pizza",
...>   location: "Stall B2",
...>   status: "active"
...> } |> Repo.insert!()

iex> pizza = %MenuItem{
...>   vendor_id: other_vendor.id,
...>   name: "Margherita Pizza",
...>   description: "Fresh mozzarella and basil",
...>   price: Decimal.new("12.99"),
...>   available: true
...> } |> Repo.insert!()
```

### Example 7: Three-Arity Permission Checks

Now let's check permissions on these resources:

```elixir
# Can this vendor update their own menu item?
iex> Scope.can?(vendor_scope, :update, burger)
true

# Can they update another vendor's item?
iex> Scope.can?(vendor_scope, :update, pizza)
false

# Can admin update anyone's items?
iex> Scope.can?(admin_scope, :update, burger)
true

iex> Scope.can?(admin_scope, :update, pizza)
true
```

**What's happening under the hood?**

The three-arity `can?/3` delegates to the Authorization module:

```elixir
# This is what happens internally
iex> alias RiverSide.Authorization

iex> Authorization.check(vendor_scope, :update, burger)
true  # Ownership check passes

iex> Authorization.check(vendor_scope, :update, pizza)
false  # Ownership check fails
```

### Example 8: Order Authorization

Let's create an order and see state-dependent authorization:

```elixir
iex> alias RiverSide.Vendors.Order

# Create a pending order
iex> pending_order = %Order{
...>   vendor_id: vendor.id,
...>   customer_name: "1234567890",
...>   table_number: "5",
...>   status: "pending",
...>   payment_status: "unpaid",
...>   total_amount: Decimal.new("25.00")
...> } |> Repo.insert!()

# Create a completed order
iex> completed_order = %Order{
...>   vendor_id: vendor.id,
...>   customer_name: "0987654321",
...>   table_number: "8",
...>   status: "completed",
...>   payment_status: "paid",
...>   total_amount: Decimal.new("35.00")
...> } |> Repo.insert!()
```

Now test state-dependent permissions:

```elixir
# Can vendor update status of pending order?
iex> Scope.can?(vendor_scope, :update_status, pending_order)
true

# Can vendor update status of completed order?
iex> Scope.can?(vendor_scope, :update_status, completed_order)
false  # Status is "completed", can't modify

# Can vendor cancel pending order?
iex> Scope.can?(vendor_scope, :cancel, pending_order)
true

# Can vendor cancel completed order?
iex> Scope.can?(vendor_scope, :cancel, completed_order)
false  # Can only cancel pending orders
```

**The lesson:**

Resource-based authorization checks THREE things:

1. ✅ **Role** - Is the user's role allowed to perform this action?
2. ✅ **Ownership** - Does the user own/have access to this resource?
3. ✅ **State** - Is the resource in a state that allows this action?

---

## Part 5: Customer Scopes - Sessionless Authentication

Customers are unique because they don't have user accounts. Let's explore how they work.

### Example 9: Creating a Customer Scope

```elixir
# Customer checks in at a table
iex> customer_scope = Scope.for_customer("555-1234", 7)
```

**Examine the structure:**

```elixir
%RiverSide.Accounts.Scope{
  user: nil,  # No user account!
  role: :customer,
  vendor: nil,
  permissions: %{
    view_menu: true,
    place_orders: true,
    view_own_orders: true,
    manage_cart: true,
    # ... 2 more
  },
  customer_info: %{
    phone: "555-1234",
    table_number: 7,
    session_started: ~U[2025-10-03 10:15:00Z]
  },
  session_id: "customer_xyz789...",
  expires_at: ~U[2025-10-03 14:15:00Z]  # 4 hours later
}
```

### Example 10: Customer Session Validation

```elixir
# Check if session is still active
iex> Scope.active_customer?(customer_scope)
true

# Get customer info
iex> Scope.customer_phone(customer_scope)
"555-1234"

iex> Scope.customer_table(customer_scope)
7

# What about expired sessions? (simulate by creating old scope)
iex> old_time = DateTime.add(DateTime.utc_now(), -5, :hour)
iex> expired_scope = %{customer_scope | expires_at: old_time}

iex> Scope.active_customer?(expired_scope)
false  # Session expired!
```

### Example 11: Customer Order Authorization

Create an order for this customer:

```elixir
iex> customer_order = %Order{
...>   vendor_id: vendor.id,
...>   customer_name: "555-1234",  # Matches phone
...>   table_number: "7",          # Matches table
...>   status: "pending",
...>   payment_status: "unpaid",
...>   total_amount: Decimal.new("18.50")
...> } |> Repo.insert!()

# Create an order for different customer
iex> other_order = %Order{
...>   vendor_id: vendor.id,
...>   customer_name: "555-9999",  # Different phone
...>   table_number: "3",          # Different table
...>   status: "pending",
...>   payment_status: "unpaid",
...>   total_amount: Decimal.new("22.00")
...> } |> Repo.insert!()
```

Now test customer authorization:

```elixir
# Can customer view their own order?
iex> Scope.can?(customer_scope, :view, customer_order)
true

# Can customer view someone else's order?
iex> Scope.can?(customer_scope, :view, other_order)
false  # Phone and table don't match

# Can customer update order status?
iex> Scope.can?(customer_scope, :update_status, customer_order)
false  # Only vendors can update status
```

**The customer authorization rule:**

A customer can only access orders where **BOTH**:
- `order.customer_name` == `scope.customer_info.phone`
- `order.table_number` == `scope.customer_info.table_number` (as string)

---

## Part 6: Query Scoping - Automatic Data Filtering

One of the most powerful features is automatic query scoping. Let's see it in action.

### Example 12: Query Scoping for Different Roles

First, let's create more test data:

```elixir
# Create orders for multiple vendors
iex> vendor1_orders = [
...>   %Order{vendor_id: vendor.id, customer_name: "111", table_number: "1",
...>          status: "pending", payment_status: "unpaid", total_amount: Decimal.new("10")} |> Repo.insert!(),
...>   %Order{vendor_id: vendor.id, customer_name: "222", table_number: "2",
...>          status: "preparing", payment_status: "unpaid", total_amount: Decimal.new("15")} |> Repo.insert!()
...> ]

iex> vendor2_orders = [
...>   %Order{vendor_id: other_vendor.id, customer_name: "333", table_number: "3",
...>          status: "ready", payment_status: "unpaid", total_amount: Decimal.new("20")} |> Repo.insert!(),
...>   %Order{vendor_id: other_vendor.id, customer_name: "444", table_number: "4",
...>          status: "completed", payment_status: "paid", total_amount: Decimal.new("25")} |> Repo.insert!()
...> ]
```

Now let's query with different scopes:

```elixir
import Ecto.Query

# Admin sees ALL orders
iex> admin_query = Authorization.scope_query(Order, admin_scope, :orders)
iex> Repo.all(admin_query) |> length()
4  # All orders

# Vendor sees only THEIR orders
iex> vendor_query = Authorization.scope_query(Order, vendor_scope, :orders)
iex> vendor_orders = Repo.all(vendor_query)
iex> length(vendor_orders)
2  # Only vendor 1's orders

iex> Enum.all?(vendor_orders, fn o -> o.vendor_id == vendor.id end)
true  # All belong to this vendor

# Customer sees only THEIR order
iex> customer_query = Authorization.scope_query(Order, customer_scope, :orders)
iex> Repo.all(customer_query) |> length()
1  # Only orders matching phone + table

# Guest sees NOTHING
iex> guest_query = Authorization.scope_query(Order, guest_scope, :orders)
iex> Repo.all(guest_query)
[]  # No access to orders
```

### Example 13: Understanding Query Transformation

Let's see what's happening to the queries:

```elixir
# Look at the raw SQL generated
iex> vendor_query = Authorization.scope_query(Order, vendor_scope, :orders)
iex> Ecto.Adapters.SQL.to_sql(:all, Repo, vendor_query)
{"SELECT o0.* FROM \"orders\" AS o0 WHERE (o0.\"vendor_id\" = $1)", [1]}
#                                           ^^^^^^^^^^^^^^^^^^^^^^^^
# Automatically added WHERE clause filtering by vendor_id!

# Compare with admin (no filtering)
iex> admin_query = Authorization.scope_query(Order, admin_scope, :orders)
iex> Ecto.Adapters.SQL.to_sql(:all, Repo, admin_query)
{"SELECT o0.* FROM \"orders\" AS o0", []}
# No WHERE clause - admin sees everything

# Customer query (filters by phone AND table)
iex> customer_query = Authorization.scope_query(Order, customer_scope, :orders)
iex> Ecto.Adapters.SQL.to_sql(:all, Repo, customer_query)
{"SELECT o0.* FROM \"orders\" AS o0 WHERE (o0.\"customer_name\" = $1) AND (o0.\"table_number\" = $2)",
 ["555-1234", "7"]}
```

**The power of query scoping:**

You write ONE query:
```elixir
Order |> Authorization.scope_query(scope, :orders) |> Repo.all()
```

And it automatically becomes the right query for each role:
- Admin → All orders
- Vendor → Their orders only
- Cashier → All orders (read-only)
- Customer → Their table's orders only
- Guest → No orders

---

## Part 7: Cashier Role - Cross-Vendor Capabilities

Cashiers have unique permissions: they can see all orders but only for payment purposes.

### Example 14: Cashier Scope and Permissions

```elixir
# Create a cashier user
iex> cashier_user = %User{
...>   email: "cashier@foodcourt.com",
...>   is_admin: false,
...>   is_vendor: false,
...>   is_cashier: true,
...>   confirmed_at: DateTime.utc_now()
...> } |> Repo.insert!()

iex> cashier_scope = Scope.for_user(cashier_user)

# Check cashier permissions
iex> Scope.can?(cashier_scope, :view_all_orders)
true

iex> Scope.can?(cashier_scope, :process_payments)
true

iex> Scope.can?(cashier_scope, :manage_menu)
false  # Cannot modify menus

iex> Scope.can?(cashier_scope, :manage_orders)
false  # Cannot update order status
```

### Example 15: Cashier Order Access

```elixir
# Cashier can VIEW any order
iex> Scope.can?(cashier_scope, :view, pending_order)
true

iex> Scope.can?(cashier_scope, :view, completed_order)
true

# Cashier can MARK orders as paid
iex> Scope.can?(cashier_scope, :mark_paid, pending_order)
true

# But cashier CANNOT update status
iex> Scope.can?(cashier_scope, :update_status, pending_order)
false

# And CANNOT cancel orders
iex> Scope.can?(cashier_scope, :cancel, pending_order)
false
```

### Example 16: Cashier Query Scoping

```elixir
# Cashier sees ALL orders (like admin, but read-only)
iex> cashier_query = Authorization.scope_query(Order, cashier_scope, :orders)
iex> Repo.all(cashier_query) |> length()
4  # All orders from all vendors

# This is different from vendor who only sees their own
iex> vendor_query = Authorization.scope_query(Order, vendor_scope, :orders)
iex> Repo.all(vendor_query) |> length()
2  # Only their orders
```

**Cashier design pattern:**

Cashiers have **read-everything, write-nothing** access to orders, EXCEPT for payment operations:

| Action | Cashier Can? | Reasoning |
|--------|--------------|-----------|
| View all orders | ✅ | Need to see what to process |
| Mark paid | ✅ | Their primary job |
| Update status | ❌ | Vendors control fulfillment |
| Cancel order | ❌ | Business decision, not payment |

---

## Part 8: Real-World Scenarios and Testing

Let's put everything together with realistic scenarios.

### Scenario 1: Vendor Updates Menu Item

```elixir
# Setup
iex> my_item = burger  # Vendor's own menu item
iex> their_item = pizza  # Other vendor's item

# Attempt to update own item
iex> if Scope.can?(vendor_scope, :update, my_item) do
...>   # In real code: Vendors.update_menu_item(my_item, %{price: Decimal.new("9.99")})
...>   IO.puts("✅ Updated my burger price")
...> else
...>   IO.puts("❌ Authorization failed")
...> end
✅ Updated my burger price

# Attempt to update other vendor's item
iex> if Scope.can?(vendor_scope, :update, their_item) do
...>   IO.puts("✅ Updated their pizza price")
...> else
...>   IO.puts("❌ Authorization failed")
...> end
❌ Authorization failed
```

### Scenario 2: Vendor Manages Order Lifecycle

```elixir
# Vendor receives new order
iex> new_order = %Order{
...>   vendor_id: vendor.id,
...>   customer_name: "555-7777",
...>   table_number: "10",
...>   status: "pending",
...>   payment_status: "unpaid",
...>   total_amount: Decimal.new("30.00")
...> } |> Repo.insert!()

# Step 1: Vendor accepts and starts preparing
iex> if Scope.can?(vendor_scope, :update_status, new_order) do
...>   IO.puts("✅ Starting to prepare order ##{new_order.id}")
...>   # Vendors.update_order_status(new_order, "preparing")
...> end
✅ Starting to prepare order #123

# Step 2: Mark as ready
iex> preparing_order = %{new_order | status: "preparing"}
iex> if Scope.can?(vendor_scope, :update_status, preparing_order) do
...>   IO.puts("✅ Order ready for pickup")
...>   # Vendors.update_order_status(preparing_order, "ready")
...> end
✅ Order ready for pickup

# Step 3: Try to mark as completed (only cashier can change payment status)
iex> ready_order = %{preparing_order | status: "ready"}
iex> if Scope.can?(vendor_scope, :update_status, ready_order) do
...>   IO.puts("✅ Marked as completed")
...> else
...>   IO.puts("❌ Cannot complete - order is already ready")
...> end
❌ Cannot complete - order is already ready

# Vendor can only update "pending" or "preparing" statuses
```

### Scenario 3: Customer Orders Food

```elixir
# Customer checks in
iex> customer_scope = Scope.for_customer("555-8888", 12)

# Customer browses menu (all vendors)
iex> Scope.can?(customer_scope, :view_menu)
true

# Customer places order
iex> Scope.can?(customer_scope, :place_orders)
true

# Create the order (simulated)
iex> customer_order = %Order{
...>   vendor_id: vendor.id,
...>   customer_name: "555-8888",
...>   table_number: "12",
...>   status: "pending",
...>   payment_status: "unpaid",
...>   total_amount: Decimal.new("45.00")
...> } |> Repo.insert!()

# Customer can view their own order
iex> Scope.can?(customer_scope, :view, customer_order)
true

# Customer CANNOT modify order status
iex> Scope.can?(customer_scope, :update_status, customer_order)
false

# Customer CAN see only their orders via query scoping
iex> customer_query = Authorization.scope_query(Order, customer_scope, :orders)
iex> my_orders = Repo.all(customer_query)
iex> Enum.all?(my_orders, fn o ->
...>   o.customer_name == "555-8888" and o.table_number == "12"
...> end)
true
```

### Scenario 4: Admin Intervenes

```elixir
# Admin needs to cancel a problematic order
iex> problematic_order = %Order{
...>   vendor_id: vendor.id,
...>   customer_name: "555-9999",
...>   table_number: "15",
...>   status: "completed",  # Already completed
...>   payment_status: "paid",
...>   total_amount: Decimal.new("50.00")
...> } |> Repo.insert!()

# Vendor cannot cancel completed orders
iex> Scope.can?(vendor_scope, :cancel, problematic_order)
false

# But admin can cancel ANY order, regardless of state
iex> Scope.can?(admin_scope, :cancel, problematic_order)
true  # Admin overrides state checks

# Admin can also access ANY vendor's data
iex> Scope.owns_vendor?(admin_scope, 999999)
true  # Admin "owns" everything
```

---

## Part 9: Debugging Authorization Issues

Let's explore techniques for debugging authorization problems.

### Debugging Technique 1: Inspecting Permission Maps

```elixir
# See all permissions for a role
iex> vendor_scope.permissions
%{
  manage_menu: true,
  manage_own_orders: true,
  view_own_orders: true,
  view_own_analytics: true,
  update_profile: true,
  view_menu: true,
  place_orders: true,
  view_transactions: true,
  cancel_own_orders: true
}

# Compare with another role
iex> cashier_scope.permissions
%{
  view_all_orders: true,
  process_payments: true,
  view_daily_transactions: true,
  view_menu: true,
  mark_order_paid: true,
  handle_refunds: true,
  view_cashier_dashboard: true
}

# Identify missing permission
iex> Map.get(vendor_scope.permissions, :process_payments, false)
false  # Vendors don't have this

iex> Map.get(cashier_scope.permissions, :process_payments, false)
true  # Cashiers do
```

### Debugging Technique 2: Tracing Authorization Decisions

```elixir
# Create a helper to trace decisions
iex> defmodule AuthDebug do
...>   alias RiverSide.Accounts.Scope
...>   alias RiverSide.Authorization
...>
...>   def trace_check(scope, action, resource) do
...>     result = Scope.can?(scope, action, resource)
...>
...>     IO.puts("""
...>
...>     Authorization Check:
...>     --------------------
...>     Role: #{scope.role}
...>     Action: #{action}
...>     Resource: #{inspect(resource.__struct__)}
...>     Resource ID: #{resource.id}
...>     Result: #{result}
...>
...>     Scope Details:
...>       Vendor ID: #{inspect(Scope.vendor_id(scope))}
...>       Is Admin: #{Scope.admin?(scope)}
...>       Is Vendor: #{Scope.vendor?(scope)}
...>
...>     Resource Details:
...>       #{if Map.has_key?(resource, :vendor_id), do: "Vendor ID: #{resource.vendor_id}", else: ""}
...>       #{if Map.has_key?(resource, :status), do: "Status: #{resource.status}", else: ""}
...>     """)
...>
...>     result
...>   end
...> end

# Use it to debug
iex> AuthDebug.trace_check(vendor_scope, :update, pizza)

Authorization Check:
--------------------
Role: vendor
Action: update
Resource: RiverSide.Vendors.MenuItem
Resource ID: 2
Result: false

Scope Details:
  Vendor ID: 1
  Is Admin: false
  Is Vendor: true

Resource Details:
  Vendor ID: 2  # <-- MISMATCH! This is why it failed

false
```

### Debugging Technique 3: Comparing Expected vs Actual

```elixir
# Build a test matrix
iex> defmodule AuthTest do
...>   def test_matrix(scope, resources) do
...>     actions = [:view, :update, :delete, :cancel, :update_status]
...>
...>     for resource <- resources,
...>         action <- actions do
...>       result = RiverSide.Accounts.Scope.can?(scope, action, resource)
...>
...>       %{
...>         resource: "#{resource.__struct__} ##{resource.id}",
...>         action: action,
...>         allowed: result
...>       }
...>     end
...>     |> Enum.filter(& &1.allowed)  # Show only allowed actions
...>   end
...> end

# Test what vendor can do
iex> AuthTest.test_matrix(vendor_scope, [burger, pizza, pending_order])
[
  %{resource: "MenuItem #1", action: :view, allowed: true},
  %{resource: "MenuItem #1", action: :update, allowed: true},
  %{resource: "MenuItem #1", action: :delete, allowed: true},
  %{resource: "MenuItem #2", action: :view, allowed: true},  # Can view other vendors
  %{resource: "Order #5", action: :view, allowed: true},
  %{resource: "Order #5", action: :update_status, allowed: true},
  %{resource: "Order #5", action: :cancel, allowed: true}
]
# Notice: Can view pizza but not update/delete it
```

---

## Part 10: Advanced Patterns and Best Practices

### Pattern 1: Context Functions with Implicit Scoping

In your Context modules, always accept scope as first parameter:

```elixir
# In lib/river_side/vendors.ex
def list_orders(%Scope{} = scope) do
  Order
  |> Authorization.scope_query(scope, :orders)
  |> order_by([o], desc: o.inserted_at)
  |> Repo.all()
end

def get_menu_item!(%Scope{} = scope, id) do
  menu_item = Repo.get!(MenuItem, id)

  # Authorization check
  if Scope.can?(scope, :view, menu_item) do
    menu_item
  else
    raise "Not authorized to view this menu item"
  end
end
```

Test it in IEx:

```elixir
iex> alias RiverSide.Vendors

# Vendor sees only their orders
iex> vendor_orders = Vendors.list_orders(vendor_scope)
iex> Enum.all?(vendor_orders, fn o -> o.vendor_id == vendor.id end)
true

# Admin sees all orders
iex> all_orders = Vendors.list_orders(admin_scope)
iex> length(all_orders) > length(vendor_orders)
true
```

### Pattern 2: LiveView Authorization Guards

```elixir
# In your LiveView module
def mount(_params, _session, socket) do
  scope = socket.assigns.current_scope

  # Early authorization check
  unless Scope.vendor?(scope) do
    {:ok, socket |> put_flash(:error, "Access denied") |> redirect(to: "/")}
  else
    # Load vendor-specific data
    orders = Vendors.list_orders(scope)  # Automatically scoped

    {:ok, assign(socket, orders: orders, vendor_name: scope.vendor.name)}
  end
end

def handle_event("cancel_order", %{"id" => id}, socket) do
  scope = socket.assigns.current_scope
  order = Vendors.get_order!(id)

  # Resource-based check
  if Scope.can?(scope, :cancel, order) do
    case Vendors.cancel_order(order) do
      {:ok, _} -> {:noreply, put_flash(socket, :info, "Order cancelled")}
      {:error, _} -> {:noreply, put_flash(socket, :error, "Failed to cancel")}
    end
  else
    error_msg = Authorization.error_message(:cancel, :order)
    {:noreply, put_flash(socket, :error, error_msg)}
  end
end
```

### Pattern 3: Conditional UI Rendering

In your templates, use scope to show/hide UI elements:

```elixir
# In a .heex template
<%= if Scope.can?(@current_scope, :update, @menu_item) do %>
  <button phx-click="edit_item" phx-value-id={@menu_item.id}>
    Edit
  </button>
<% end %>

<%= if Scope.can?(@current_scope, :delete, @menu_item) do %>
  <button phx-click="delete_item" phx-value-id={@menu_item.id}>
    Delete
  </button>
<% end %>

# Different content per role
<%= if Scope.admin?(@current_scope) do %>
  <.link navigate="/admin/dashboard">Admin Dashboard</.link>
<% end %>

<%= if Scope.vendor?(@current_scope) do %>
  <p>Welcome, <%= @current_scope.vendor.name %></p>
<% end %>
```

---

## Part 11: Performance Considerations

### Optimization 1: Preloading Context

The vendor context is automatically preloaded, but be aware:

```elixir
# GOOD: Vendor is already loaded in scope
iex> vendor_scope.vendor.name
"Bob's Burger Stand"  # No database query

# BAD: Manually querying vendor
iex> user = vendor_scope.user
iex> vendor = Vendors.get_vendor_by_user_id(user.id)  # Unnecessary query!
```

### Optimization 2: Query Scoping vs Manual Filtering

```elixir
# GOOD: Query scoping at database level
iex> Order
...> |> Authorization.scope_query(vendor_scope, :orders)
...> |> Repo.all()
# SQL: SELECT * FROM orders WHERE vendor_id = 1

# BAD: Loading all and filtering in memory
iex> Order
...> |> Repo.all()
...> |> Enum.filter(fn o -> o.vendor_id == vendor.id end)
# SQL: SELECT * FROM orders  (loads everything!)
```

### Optimization 3: Permission Caching

Permissions are computed once per scope creation:

```elixir
# Scope created once during login
iex> scope = Scope.for_user(user)

# Permission checks are simple map lookups (O(1))
iex> Scope.can?(scope, :manage_menu)  # Fast
iex> Scope.can?(scope, :process_payments)  # Fast
iex> Scope.can?(scope, :view_analytics)  # Fast

# No database queries, no computation
```

---

## Part 12: Testing Authorization

### Writing Authorization Tests

```elixir
# In test/river_side/authorization_test.exs
defmodule RiverSide.AuthorizationTest do
  use RiverSide.DataCase

  alias RiverSide.Accounts.Scope
  alias RiverSide.Authorization
  alias RiverSide.Vendors.{Vendor, MenuItem, Order}

  setup do
    # Create test users
    admin = insert_user(is_admin: true)
    vendor_user = insert_user(is_vendor: true)
    vendor = insert_vendor(user_id: vendor_user.id)

    # Create test resources
    menu_item = insert_menu_item(vendor_id: vendor.id)
    order = insert_order(vendor_id: vendor.id, status: "pending")

    # Create scopes
    admin_scope = Scope.for_user(admin)
    vendor_scope = Scope.for_user(vendor_user)

    %{
      admin_scope: admin_scope,
      vendor_scope: vendor_scope,
      menu_item: menu_item,
      order: order,
      vendor: vendor
    }
  end

  describe "menu item authorization" do
    test "vendor can update own menu item", %{vendor_scope: scope, menu_item: item} do
      assert Scope.can?(scope, :update, item)
    end

    test "vendor cannot update other vendor's menu item", %{vendor_scope: scope} do
      other_item = insert_menu_item(vendor_id: 9999)
      refute Scope.can?(scope, :update, other_item)
    end

    test "admin can update any menu item", %{admin_scope: scope, menu_item: item} do
      assert Scope.can?(scope, :update, item)
    end
  end

  describe "order status updates" do
    test "vendor can update pending order", %{vendor_scope: scope, order: order} do
      assert Scope.can?(scope, :update_status, order)
    end

    test "vendor cannot update completed order", %{vendor_scope: scope} do
      completed_order = insert_order(vendor_id: scope.vendor.id, status: "completed")
      refute Scope.can?(scope, :update_status, completed_order)
    end
  end
end
```

Try running tests in IEx:

```elixir
# Load test helpers
iex> Code.require_file("test/support/fixtures/accounts_fixtures.ex")
iex> Code.require_file("test/support/fixtures/vendors_fixtures.ex")

# Run individual tests
iex> ExUnit.start(auto_run: false)
iex> ExUnit.run()
```

---

## Conclusion

### What We've Covered

1. **Philosophy** - Why scope-based authorization solves multi-tenant problems
2. **Structure** - The anatomy of a scope and its components
3. **Roles** - Five user types with distinct permissions and context
4. **Two-Layer Auth** - Permission-based and resource-based checks
5. **Ownership** - Automatic vendor context loading and ownership verification
6. **State-Dependent** - Authorization that considers resource state
7. **Query Scoping** - Automatic database-level filtering
8. **Customer Sessions** - Sessionless authentication for table-based ordering
9. **Cashier Pattern** - Cross-vendor read access with limited write permissions
10. **Real-World Usage** - Patterns for Context modules and LiveView
11. **Debugging** - Techniques for tracing authorization decisions
12. **Testing** - Writing comprehensive authorization tests

### Key Takeaways

✅ **Scope is the foundation** - Everything authorization-related flows through scopes

✅ **Two permission types** - Boolean (`can?/2`) vs Resource (`can?/3`)

✅ **Context is automatic** - Vendor records are preloaded for quick access

✅ **State matters** - Some actions depend on resource state (order status)

✅ **Query scoping is powerful** - One query works for all roles

✅ **Default deny** - Unknown actions are blocked automatically

✅ **Layered security** - Route → Permission → Resource → Query checks

### Next Steps

1. **Explore the codebase**:
   - Read `lib/river_side/accounts/scope.ex` line by line
   - Study `lib/river_side/authorization.ex` policy functions
   - Examine LiveView modules to see real usage

2. **Experiment in IEx**:
   - Create different scopes and test permissions
   - Build complex scenarios with multiple resources
   - Debug authorization issues with tracing

3. **Extend the system**:
   - Add new permissions to roles
   - Create new resource policies
   - Implement custom authorization logic

4. **Apply the pattern**:
   - Use this architecture in your own projects
   - Adapt it for different user types
   - Build domain-specific authorization rules

### Further Reading

- [CLAUDE.md](CLAUDE.md) - Project overview and architecture
- [SCOPE_IMPLEMENTATION_GUIDE.md](docs/SCOPE_IMPLEMENTATION_GUIDE.md) - Detailed implementation guide
- [AUTHORIZATION_EXPLAINED.md](AUTHORIZATION_EXPLAINED.md) - Quick reference guide
- [Phoenix LiveView Authorization Patterns](https://hexdocs.pm/phoenix_live_view/security.html)

---

## Appendix: Quick Reference Commands

### Starting IEx

```bash
cd /path/to/river_side
iex -S mix
```

### Creating Test Scopes

```elixir
# Admin
admin = %RiverSide.Accounts.User{is_admin: true, email: "admin@test.com", confirmed_at: DateTime.utc_now()} |> RiverSide.Repo.insert!()
admin_scope = RiverSide.Accounts.Scope.for_user(admin)

# Vendor
vendor_user = %RiverSide.Accounts.User{is_vendor: true, email: "vendor@test.com", confirmed_at: DateTime.utc_now()} |> RiverSide.Repo.insert!()
vendor = %RiverSide.Vendors.Vendor{user_id: vendor_user.id, name: "Test Vendor", description: "Test", location: "A1", status: "active"} |> RiverSide.Repo.insert!()
vendor_scope = RiverSide.Accounts.Scope.for_user(vendor_user)

# Customer
customer_scope = RiverSide.Accounts.Scope.for_customer("555-1234", 5)

# Guest
guest_scope = RiverSide.Accounts.Scope.for_guest()
```

### Common Checks

```elixir
alias RiverSide.Accounts.Scope

# Role checks
Scope.admin?(scope)
Scope.vendor?(scope)
Scope.authenticated?(scope)

# Permission checks
Scope.can?(scope, :manage_menu)
Scope.can?(scope, :update, resource)

# Ownership
Scope.owns_vendor?(scope, vendor_id)
Scope.vendor_id(scope)

# Query scoping
RiverSide.Authorization.scope_query(query, scope, :orders)
```

---

**© 2025 River Side Food Court Management System**

*This chapter is part of the official River Side documentation. For updates and contributions, visit the project repository.*
