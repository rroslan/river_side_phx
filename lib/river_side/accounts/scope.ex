defmodule RiverSide.Accounts.Scope do
  @moduledoc """
  Enhanced scope for River Side Food Court's multi-role system.

  This module defines the scope of the caller to be used throughout the app,
  handling authentication context for admin, vendor, cashier, and customer users.

  The scope carries user information, role-based permissions, and preloaded
  context data (like vendor information for vendor users).
  """

  alias RiverSide.Accounts.User
  alias RiverSide.Vendors
  alias RiverSide.Vendors.Vendor

  defstruct [
    :user,
    # :admin, :vendor, :cashier, :customer, :guest
    :role,
    # Preloaded vendor for vendor users
    :vendor,
    # Map of allowed actions
    :permissions,
    # For customer sessions (phone, table_number)
    :customer_info,
    # Unique session identifier
    :session_id,
    # Session expiration (mainly for customers)
    :expires_at
  ]

  @doc """
  Creates a scope for an authenticated user.

  Automatically determines the user's role, loads relevant context data
  (like vendor information), and assigns appropriate permissions.
  """
  def for_user(%User{} = user) do
    base_scope = %__MODULE__{
      user: user,
      role: determine_role(user),
      session_id: generate_session_id(),
      expires_at: nil
    }

    base_scope
    |> load_vendor_context()
    |> assign_permissions()
  end

  def for_user(nil), do: for_guest()

  @doc """
  Creates a scope for a customer (non-authenticated user with table/phone).

  Customer sessions expire after 4 hours.
  """
  def for_customer(phone, table_number) when is_binary(phone) and is_integer(table_number) do
    %__MODULE__{
      user: nil,
      role: :customer,
      customer_info: %{
        phone: phone,
        table_number: table_number,
        session_started: DateTime.utc_now()
      },
      permissions: customer_permissions(),
      session_id: generate_session_id(),
      expires_at: DateTime.add(DateTime.utc_now(), 4, :hour)
    }
  end

  @doc """
  Creates a guest scope for unauthenticated users.
  """
  def for_guest do
    %__MODULE__{
      user: nil,
      role: :guest,
      permissions: guest_permissions(),
      session_id: generate_session_id()
    }
  end

  # Role check functions
  @doc "Checks if the scope belongs to an admin user"
  def admin?(%__MODULE__{role: :admin}), do: true
  def admin?(_), do: false

  @doc "Checks if the scope belongs to a vendor user"
  def vendor?(%__MODULE__{role: :vendor}), do: true
  def vendor?(_), do: false

  @doc "Checks if the scope belongs to a cashier user"
  def cashier?(%__MODULE__{role: :cashier}), do: true
  def cashier?(_), do: false

  @doc "Checks if the scope belongs to a customer"
  def customer?(%__MODULE__{role: :customer}), do: true
  def customer?(_), do: false

  @doc "Checks if the scope belongs to a guest"
  def guest?(%__MODULE__{role: :guest}), do: true
  def guest?(_), do: false

  @doc "Checks if the scope has an authenticated user"
  def authenticated?(%__MODULE__{user: %User{}}), do: true
  def authenticated?(_), do: false

  @doc "Checks if the scope has a specific permission"
  def can?(%__MODULE__{permissions: perms}, action) when is_atom(action) do
    Map.get(perms, action, false)
  end

  def can?(_, _), do: false

  @doc "Checks if the scope can perform an action on a specific resource"
  def can?(%__MODULE__{} = scope, action, resource) do
    RiverSide.Authorization.check(scope, action, resource)
  end

  # Convenience permission checks
  def can_manage_orders?(%__MODULE__{} = scope) do
    can?(scope, :manage_orders)
  end

  def can_process_payments?(%__MODULE__{} = scope) do
    can?(scope, :process_payments)
  end

  def can_manage_menu?(%__MODULE__{} = scope) do
    can?(scope, :manage_menu)
  end

  def can_view_all_vendors?(%__MODULE__{} = scope) do
    can?(scope, :view_all_vendors)
  end

  def can_manage_vendors?(%__MODULE__{} = scope) do
    can?(scope, :manage_vendors)
  end

  # Vendor-specific helpers
  @doc "Checks if the scope owns a specific vendor"
  def owns_vendor?(%__MODULE__{role: :vendor, vendor: %{id: vendor_id}}, check_vendor_id)
      when is_integer(check_vendor_id) do
    vendor_id == check_vendor_id
  end

  def owns_vendor?(%__MODULE__{role: :admin}, _), do: true

  def owns_vendor?(%__MODULE__{} = scope, %{vendor_id: vendor_id}) do
    owns_vendor?(scope, vendor_id)
  end

  def owns_vendor?(_, _), do: false

  # Customer-specific helpers
  @doc "Checks if a customer session is still active"
  def active_customer?(%__MODULE__{role: :customer, expires_at: expires_at}) do
    DateTime.compare(expires_at, DateTime.utc_now()) == :gt
  end

  def active_customer?(_), do: false

  @doc "Gets the customer's phone number from scope"
  def customer_phone(%__MODULE__{role: :customer, customer_info: %{phone: phone}}), do: phone
  def customer_phone(_), do: nil

  @doc "Gets the customer's table number from scope"
  def customer_table(%__MODULE__{role: :customer, customer_info: %{table_number: table}}),
    do: table

  def customer_table(_), do: nil

  @doc "Gets the vendor ID from scope"
  def vendor_id(%__MODULE__{vendor: %{id: id}}), do: id
  def vendor_id(_), do: nil

  # Private functions

  defp determine_role(%User{} = user) do
    cond do
      user.is_admin -> :admin
      user.is_vendor -> :vendor
      user.is_cashier -> :cashier
      true -> :guest
    end
  end

  defp load_vendor_context(%__MODULE__{role: :vendor, user: %{id: user_id}} = scope) do
    case Vendors.get_vendor_by_user_id(user_id) do
      %Vendor{} = vendor -> %{scope | vendor: vendor}
      nil -> scope
    end
  end

  defp load_vendor_context(scope), do: scope

  defp assign_permissions(%__MODULE__{role: role} = scope) do
    permissions =
      case role do
        :admin -> admin_permissions()
        :vendor -> vendor_permissions()
        :cashier -> cashier_permissions()
        :customer -> customer_permissions()
        _ -> guest_permissions()
      end

    %{scope | permissions: permissions}
  end

  defp generate_session_id do
    :crypto.strong_rand_bytes(16) |> Base.encode64()
  end

  # Permission definitions

  defp admin_permissions do
    %{
      # Vendor management
      view_all_vendors: true,
      manage_vendors: true,
      create_vendor: true,
      update_vendor: true,
      delete_vendor: true,

      # Order management
      view_all_orders: true,
      manage_orders: true,
      update_any_order: true,
      cancel_any_order: true,

      # Menu management
      manage_menu: true,
      update_any_menu_item: true,
      delete_any_menu_item: true,

      # Financial
      process_payments: true,
      view_all_transactions: true,
      process_refunds: true,
      view_analytics: true,

      # System
      manage_users: true,
      view_system_logs: true,
      access_admin_dashboard: true,
      access_vendor_dashboard: true,
      access_cashier_dashboard: true
    }
  end

  defp vendor_permissions do
    %{
      # Menu management
      view_own_menu: true,
      manage_menu: true,
      create_menu_item: true,
      update_own_menu_item: true,
      delete_own_menu_item: true,

      # Order management
      view_own_orders: true,
      manage_orders: true,
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

  defp cashier_permissions do
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

  defp customer_permissions do
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

  defp guest_permissions do
    %{
      view_menu: true,
      view_table_availability: true
    }
  end
end
