# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

River Side is a multi-vendor food court management system built with Phoenix 1.8.1 and Elixir. It features role-based access control, real-time order processing, vendor management, and customer ordering capabilities. The application uses a sophisticated scope-based authorization system for handling five user types: Admin, Vendor, Cashier, Customer, and Guest.

## Essential Commands

### Development
```bash
# Start the development server
mix phx.server

# Run in interactive mode
iex -S mix phx.server
```

### Database Operations
```bash
# Full database setup (create, migrate, seed)
mix ecto.setup

# Reset database (drop and setup)
mix ecto.reset

# Create migration
mix ecto.gen.migration migration_name

# Run migrations
mix ecto.migrate

# Run seeds (requires env vars ADMIN_EMAIL, VENDOR_EMAIL, CASHIER_EMAIL)
mix run priv/repo/seeds.exs
```

### Testing
```bash
# Run all tests (automatically creates and migrates test database)
mix test

# Run specific test file
mix test test/path/to/test_file.exs

# Run test at specific line
mix test test/path/to/test_file.exs:42

# Run tests with detailed output
mix test --trace
```

### Code Quality
```bash
# Format code
mix format

# Run Credo static analysis
mix credo

# Run security checks
mix sobelow
```

### Asset Management
```bash
# Install asset tools
mix assets.setup

# Build assets (Tailwind + esbuild)
mix assets.build

# Build and minify for deployment
mix assets.deploy
```

### Project Setup
```bash
# Full project setup including dependencies, database, and assets
mix setup
```

## Architecture Overview

### Scope-Based Authorization System

The application's core architectural pattern is a **scope-based authorization system** that provides context-aware, role-based access control. This is the most important architectural concept to understand.

#### Key Components

**1. Scope Module (`lib/river_side/accounts/scope.ex`)**
- Central abstraction for user context and permissions
- Automatically loads role-specific data (e.g., preloads vendor record for vendor users)
- Manages both authenticated users and customer sessions
- Contains role-based permission maps

**2. Authorization Module (`lib/river_side/authorization.ex`)**
- Resource-based access control policies
- Handles ownership checks (e.g., can vendor update their own menu items?)
- Query scoping to filter data based on user permissions
- Provides user-friendly error messages for authorization failures

**3. UserAuth Module (`lib/river_side_web/user_auth.ex`)**
- Creates scopes during authentication
- Implements role-specific mount callbacks for LiveView
- Handles magic link authentication flow
- Provides role-based redirects after login

#### Scope Structure
```elixir
%Scope{
  user: %User{},           # nil for customers/guests
  role: :admin,            # :admin, :vendor, :cashier, :customer, :guest
  vendor: %Vendor{},       # Preloaded for vendor users
  permissions: %{},        # Role-specific permission map
  customer_info: %{},      # Customer session data (phone, table)
  session_id: "...",       # Unique session identifier
  expires_at: ~U[...]      # Session expiration (for customers)
}
```

#### Using Scopes in LiveView

All LiveView modules receive `@current_scope` assign via mount callbacks:
```elixir
def mount(_params, _session, socket) do
  # Access current user's scope
  scope = socket.assigns.current_scope

  # Check role
  if Scope.vendor?(scope) do
    # Access preloaded vendor
    vendor = scope.vendor
  end

  # Check permissions
  if Scope.can?(scope, :manage_menu) do
    # Allow action
  end

  # Resource-based authorization
  if Scope.can?(scope, :update, menu_item) do
    # Allow update
  end
end
```

### Application Structure

```
lib/
├── river_side/                    # Business logic layer
│   ├── accounts/                  # Authentication & user management
│   │   ├── scope.ex              # Core scope abstraction
│   │   ├── user.ex               # User schema
│   │   └── user_notifier.ex      # Email notifications
│   ├── authorization.ex           # Resource-based policies
│   ├── vendors/                   # Domain logic
│   │   ├── vendor.ex             # Vendor schema
│   │   ├── menu_item.ex          # Menu item schema
│   │   └── order.ex              # Order schema
│   ├── tables/                    # Table management
│   │   └── table.ex              # Table schema
│   ├── accounts.ex               # User context
│   ├── vendors.ex                # Vendor context
│   ├── tables.ex                 # Table context
│   └── reports.ex                # Analytics & reporting
└── river_side_web/               # Web interface layer
    ├── controllers/
    │   └── user_session_controller.ex  # Magic link auth
    ├── live/                     # LiveView modules
    │   ├── admin_live/           # Admin dashboard & user mgmt
    │   ├── vendor_live/          # Vendor dashboard, menu, orders
    │   ├── cashier_live/         # Payment processing
    │   ├── customer_live/        # Customer ordering
    │   └── table_live/           # Table check-in
    ├── components/               # Reusable UI components
    ├── hooks/                    # LiveView hooks
    ├── user_auth.ex             # Auth plugs & scope management
    └── router.ex                # Route definitions with scope guards
```

### Route Protection

Routes are protected using role-specific `on_mount` callbacks:
```elixir
# Admin-only routes
live_session :admin,
  on_mount: [{RiverSideWeb.UserAuth, :require_admin_scope}] do
  live "/admin/dashboard", AdminLive.Dashboard
end

# Vendor-only routes
live_session :vendor,
  on_mount: [{RiverSideWeb.UserAuth, :require_vendor_scope}] do
  live "/vendor/dashboard", VendorLive.Dashboard
end
```

### Database Schema Relationships

**Core Entities:**
- `users` - Authentication (boolean flags: is_admin, is_vendor, is_cashier)
- `vendors` - Vendor profiles (belongs to user)
- `menu_items` - Menu entries (belongs to vendor)
- `orders` - Customer orders (belongs to vendor, has many order_items)
- `order_items` - Line items (belongs to order and menu_item)
- `tables` - Physical tables with cart management

**Important Cascading Behavior:**
- Deleting a vendor cascades to menu_items and orders (sets vendor_id to null)
- Deleting a user does NOT cascade to vendor (handled in application logic)

## Authentication Flow

1. **Passwordless Magic Links**: Users enter email, receive magic link
2. **Token Validation**: Token verified in UserSessionController
3. **Scope Creation**: `UserAuth.log_in_user/3` creates scope via `Scope.for_user/1`
4. **Role-Based Redirect**: User sent to appropriate dashboard based on role
5. **Scope Loading**: Subsequent requests load scope via `fetch_current_scope_for_user/2`

## Real-Time Features

The application uses Phoenix PubSub for real-time updates:
- Order status changes broadcast to vendor and cashier dashboards
- Menu item updates reflect immediately
- Statistics update in real-time

## Environment Variables

Required for seed data:
```bash
ADMIN_EMAIL=admin@example.com
VENDOR_EMAIL=vendor1@example.com
CASHIER_EMAIL=cashier1@example.com
```

## Common Development Patterns

### Adding New Permissions

1. Add permission to role's permission map in `lib/river_side/accounts/scope.ex`
2. Add resource policy in `lib/river_side/authorization.ex` if needed
3. Use permission check in LiveView: `Scope.can?(scope, :new_permission)`

### Creating New Protected Routes

1. Add route to appropriate `live_session` group in router
2. Use `:require_#{role}_scope` on_mount callback
3. Access `@current_scope` in LiveView mount/handle_event

### Working with Vendor Context

For vendor users, the vendor record is automatically preloaded:
```elixir
# In any LiveView
vendor_id = socket.assigns.current_scope.vendor.id
vendor_name = socket.assigns.current_scope.vendor.name
```

### Query Scoping

Use `Authorization.scope_query/3` to filter queries by permissions:
```elixir
# Automatically filters based on user's role
Order
|> Authorization.scope_query(scope, :orders)
|> Repo.all()
```

## Testing Considerations

- Test database is automatically created and migrated before tests run
- Use test fixtures in `test/support/fixtures/` for test data
- Scope-based tests should verify both permission checks and resource ownership
- LiveView tests require scope assigns to be set up properly

## Important Files to Reference

- `docs/SCOPE_IMPLEMENTATION_GUIDE.md` - Comprehensive scope system documentation
- `docs/SCOPE_CHANGES_QUICK_REFERENCE.md` - Quick reference for scope usage
- `README.md` - User-facing documentation and feature overview
- `DASHBOARD.md` - Dashboard user guides for each role

## Code Style

- Use `mix format` before committing
- Follow Elixir naming conventions (snake_case for functions, PascalCase for modules)
- Prefer pattern matching over conditional logic
- Use pipelines for data transformation
- Document public functions with `@doc` and `@moduledoc`
