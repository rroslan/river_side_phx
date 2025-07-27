defmodule RiverSide.Authorization do
  @moduledoc """
  Centralized authorization logic for River Side Food Court.

  This module handles resource-based authorization checks, determining if a given
  scope can perform specific actions on resources like orders, menu items, etc.
  """

  alias RiverSide.Accounts.Scope
  alias RiverSide.Vendors.{Order, MenuItem, Vendor}

  @doc """
  Checks if a scope can perform an action on a resource.

  ## Examples

      iex> Authorization.check(scope, :view, order)
      true

      iex> Authorization.check(scope, :update, menu_item)
      false
  """
  def check(%Scope{} = scope, action, resource) do
    case {action, resource} do
      # Order authorization
      {:view, %Order{} = order} ->
        can_view_order?(scope, order)

      {:update, %Order{} = order} ->
        can_update_order?(scope, order)

      {:update_status, %Order{} = order} ->
        can_update_order_status?(scope, order)

      {:cancel, %Order{} = order} ->
        can_cancel_order?(scope, order)

      {:mark_paid, %Order{} = order} ->
        can_mark_order_paid?(scope, order)

      # Menu item authorization
      {:view, %MenuItem{} = item} ->
        can_view_menu_item?(scope, item)

      {:create, %MenuItem{}} ->
        can_create_menu_item?(scope)

      {:update, %MenuItem{} = item} ->
        can_update_menu_item?(scope, item)

      {:delete, %MenuItem{} = item} ->
        can_delete_menu_item?(scope, item)

      # Vendor authorization
      {:view, %Vendor{} = vendor} ->
        can_view_vendor?(scope, vendor)

      {:update, %Vendor{} = vendor} ->
        can_update_vendor?(scope, vendor)

      {:delete, %Vendor{} = vendor} ->
        can_delete_vendor?(scope, vendor)

      # Default deny
      _ ->
        false
    end
  end

  # Order permissions

  defp can_view_order?(%Scope{role: :admin}, _order), do: true
  defp can_view_order?(%Scope{role: :cashier}, _order), do: true

  defp can_view_order?(%Scope{role: :vendor} = scope, %Order{vendor_id: vendor_id}) do
    Scope.owns_vendor?(scope, vendor_id)
  end

  defp can_view_order?(%Scope{role: :customer} = scope, %Order{} = order) do
    order.customer_name == Scope.customer_phone(scope) &&
      order.table_number == to_string(Scope.customer_table(scope))
  end

  defp can_view_order?(_, _), do: false

  defp can_update_order?(%Scope{role: :admin}, _order), do: true

  defp can_update_order?(%Scope{role: :vendor} = scope, %Order{vendor_id: vendor_id}) do
    Scope.owns_vendor?(scope, vendor_id)
  end

  defp can_update_order?(_, _), do: false

  defp can_update_order_status?(%Scope{role: :admin}, _order), do: true

  defp can_update_order_status?(%Scope{role: :vendor} = scope, %Order{
         vendor_id: vendor_id,
         status: status
       }) do
    Scope.owns_vendor?(scope, vendor_id) && status in ["pending", "preparing"]
  end

  defp can_update_order_status?(_, _), do: false

  defp can_cancel_order?(%Scope{role: :admin}, _order), do: true

  defp can_cancel_order?(%Scope{role: :vendor} = scope, %Order{
         vendor_id: vendor_id,
         status: "pending"
       }) do
    Scope.owns_vendor?(scope, vendor_id)
  end

  defp can_cancel_order?(_, _), do: false

  defp can_mark_order_paid?(%Scope{role: :admin}, _order), do: true
  defp can_mark_order_paid?(%Scope{role: :cashier}, _order), do: true
  defp can_mark_order_paid?(_, _), do: false

  # Menu item permissions

  # Everyone can view menu items
  defp can_view_menu_item?(_scope, _item), do: true

  defp can_create_menu_item?(%Scope{role: :admin}), do: true
  defp can_create_menu_item?(%Scope{role: :vendor}), do: true
  defp can_create_menu_item?(_), do: false

  defp can_update_menu_item?(%Scope{role: :admin}, _item), do: true

  defp can_update_menu_item?(%Scope{role: :vendor} = scope, %MenuItem{vendor_id: vendor_id}) do
    Scope.owns_vendor?(scope, vendor_id)
  end

  defp can_update_menu_item?(_, _), do: false

  defp can_delete_menu_item?(%Scope{role: :admin}, _item), do: true

  defp can_delete_menu_item?(%Scope{role: :vendor} = scope, %MenuItem{vendor_id: vendor_id}) do
    Scope.owns_vendor?(scope, vendor_id)
  end

  defp can_delete_menu_item?(_, _), do: false

  # Vendor permissions

  defp can_view_vendor?(%Scope{role: :admin}, _vendor), do: true

  defp can_view_vendor?(%Scope{role: :vendor} = scope, %Vendor{id: vendor_id}) do
    Scope.owns_vendor?(scope, vendor_id)
  end

  defp can_view_vendor?(_, _), do: false

  defp can_update_vendor?(%Scope{role: :admin}, _vendor), do: true

  defp can_update_vendor?(%Scope{role: :vendor} = scope, %Vendor{id: vendor_id}) do
    Scope.owns_vendor?(scope, vendor_id)
  end

  defp can_update_vendor?(_, _), do: false

  defp can_delete_vendor?(%Scope{role: :admin}, _vendor), do: true
  defp can_delete_vendor?(_, _), do: false

  @doc """
  Checks if a scope can perform a bulk action.

  ## Examples

      iex> Authorization.can_bulk?(scope, :view_all_orders)
      true
  """
  def can_bulk?(%Scope{} = scope, action) when is_atom(action) do
    case {scope.role, action} do
      {:admin, _} -> true
      {:vendor, :view_own_orders} -> true
      {:vendor, :manage_own_menu} -> true
      {:cashier, :view_payment_queue} -> true
      {:cashier, :process_payments} -> true
      {:customer, :view_own_orders} -> true
      _ -> false
    end
  end

  @doc """
  Filters a list of resources based on what the scope can view.

  ## Examples

      iex> Authorization.filter_viewable(scope, orders)
      [%Order{}, %Order{}]
  """
  def filter_viewable(%Scope{} = scope, resources) when is_list(resources) do
    Enum.filter(resources, fn resource ->
      check(scope, :view, resource)
    end)
  end

  @doc """
  Scopes a query based on what the scope can access.

  This is useful for prefiltering database queries.
  """
  def scope_query(%Scope{} = scope, query, resource_type) do
    case {scope.role, resource_type} do
      {:admin, _} ->
        # Admins can see everything
        query

      {:vendor, :orders} ->
        # Vendors can only see their own orders
        import Ecto.Query
        where(query, [o], o.vendor_id == ^Scope.vendor_id(scope))

      {:vendor, :menu_items} ->
        # Vendors can only see their own menu items
        import Ecto.Query
        where(query, [m], m.vendor_id == ^Scope.vendor_id(scope))

      {:customer, :orders} ->
        # Customers can only see their own orders
        import Ecto.Query
        phone = Scope.customer_phone(scope)
        table = to_string(Scope.customer_table(scope))
        where(query, [o], o.customer_name == ^phone and o.table_number == ^table)

      {:cashier, :orders} ->
        # Cashiers can see all orders
        query

      _ ->
        # Default: no access
        import Ecto.Query
        where(query, [_], false)
    end
  end

  @doc """
  Returns a user-friendly error message for authorization failures.
  """
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
end
