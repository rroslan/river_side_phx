defmodule RiverSide.Vendors.VendorCleanup do
  @moduledoc """
  Service module for handling vendor deletion with proper cascade cleanup.
  This ensures all related data is properly removed when a vendor is deleted.
  """

  alias RiverSide.{Repo, Vendors, Accounts}
  alias RiverSide.Vendors.{Vendor, Order, OrderItem, MenuItem}
  import Ecto.Query, warn: false
  require Logger

  @doc """
  Deletes a vendor and all associated data in a transaction.
  Returns {:ok, deleted_info} or {:error, reason}
  """
  def delete_vendor_with_cascade(%Vendor{} = vendor) do
    Repo.transaction(fn ->
      try do
        # Preload associations for logging
        vendor = Repo.preload(vendor, [:user, :menu_items, :orders])

        Logger.info("Starting cascade deletion for vendor: #{vendor.name} (ID: #{vendor.id})")

        # Track what we're deleting for the response
        deleted_info = %{
          vendor_id: vendor.id,
          vendor_name: vendor.name,
          user_id: vendor.user_id,
          user_email: vendor.user.email,
          menu_items_count: 0,
          orders_count: 0,
          order_items_count: 0
        }

        # 1. Delete all order items for this vendor's orders
        order_items_deleted = delete_order_items_for_vendor(vendor.id)
        deleted_info = Map.put(deleted_info, :order_items_count, order_items_deleted)

        # 2. Delete all orders for this vendor
        orders_deleted = delete_orders_for_vendor(vendor.id)
        deleted_info = Map.put(deleted_info, :orders_count, orders_deleted)

        # 3. Delete all menu items for this vendor
        menu_items_deleted = delete_menu_items_for_vendor(vendor.id)
        deleted_info = Map.put(deleted_info, :menu_items_count, menu_items_deleted)

        # 4. Delete the vendor profile
        case Repo.delete(vendor) do
          {:ok, _vendor} ->
            Logger.info("Vendor profile deleted successfully")

          {:error, reason} ->
            Logger.error("Failed to delete vendor profile: #{inspect(reason)}")
            Repo.rollback({:vendor_deletion_failed, reason})
        end

        # 5. Update or delete the associated user based on roles
        handle_user_deletion(vendor.user, deleted_info)
      rescue
        e ->
          Logger.error("Error during vendor cascade deletion: #{inspect(e)}")
          Repo.rollback({:cascade_deletion_error, e})
      end
    end)
  end

  @doc """
  Deletes a vendor user and all associated vendor data if they have a vendor profile.
  """
  def delete_vendor_user(%Accounts.User{} = user) do
    if user.is_vendor do
      case Repo.get_by(Vendor, user_id: user.id) do
        nil ->
          # No vendor profile, just delete the user
          delete_user(user)

        vendor ->
          # Has vendor profile, do cascade deletion
          delete_vendor_with_cascade(vendor)
      end
    else
      # Not a vendor user, just delete normally
      delete_user(user)
    end
  end

  # Private functions

  defp delete_order_items_for_vendor(vendor_id) do
    query =
      from oi in OrderItem,
        join: o in Order,
        on: o.id == oi.order_id,
        where: o.vendor_id == ^vendor_id

    {count, _} = Repo.delete_all(query)
    Logger.info("Deleted #{count} order items for vendor #{vendor_id}")
    count
  end

  defp delete_orders_for_vendor(vendor_id) do
    query = from o in Order, where: o.vendor_id == ^vendor_id

    {count, _} = Repo.delete_all(query)
    Logger.info("Deleted #{count} orders for vendor #{vendor_id}")
    count
  end

  defp delete_menu_items_for_vendor(vendor_id) do
    query = from m in MenuItem, where: m.vendor_id == ^vendor_id

    {count, _} = Repo.delete_all(query)
    Logger.info("Deleted #{count} menu items for vendor #{vendor_id}")
    count
  end

  defp handle_user_deletion(user, deleted_info) do
    # Check if user has other roles
    has_other_roles = user.is_admin || user.is_cashier

    if has_other_roles do
      # User has other roles, just remove vendor role
      case Accounts.update_user_roles(user, %{is_vendor: false}) do
        {:ok, _updated_user} ->
          Logger.info("Removed vendor role from user #{user.email}")
          Map.put(deleted_info, :user_action, :role_removed)

        {:error, reason} ->
          Logger.error("Failed to update user roles: #{inspect(reason)}")
          Repo.rollback({:user_update_failed, reason})
      end
    else
      # User has no other roles, delete the user account
      case delete_user(user) do
        {:ok, _} ->
          Logger.info("Deleted user account #{user.email}")
          Map.put(deleted_info, :user_action, :deleted)

        {:error, reason} ->
          Logger.error("Failed to delete user: #{inspect(reason)}")
          Repo.rollback({:user_deletion_failed, reason})
      end
    end
  end

  defp delete_user(user) do
    # Delete all user tokens first (sessions, etc.)
    Repo.delete_all(from t in Accounts.UserToken, where: t.user_id == ^user.id)

    # Delete the user
    Repo.delete(user)
  end

  @doc """
  Checks if a vendor can be safely deleted (for UI warnings).
  Returns a map with information about what would be deleted.
  """
  def check_vendor_deletion_impact(%Vendor{} = vendor) do
    vendor = Repo.preload(vendor, [:user])

    order_count =
      Repo.aggregate(
        from(o in Order, where: o.vendor_id == ^vendor.id),
        :count
      )

    active_order_count =
      Repo.aggregate(
        from(o in Order,
          where: o.vendor_id == ^vendor.id and o.status not in ["completed", "cancelled"]
        ),
        :count
      )

    menu_item_count =
      Repo.aggregate(
        from(m in MenuItem, where: m.vendor_id == ^vendor.id),
        :count
      )

    order_item_count =
      Repo.aggregate(
        from(oi in OrderItem,
          join: o in Order,
          on: o.id == oi.order_id,
          where: o.vendor_id == ^vendor.id
        ),
        :count
      )

    user_has_other_roles = vendor.user.is_admin || vendor.user.is_cashier

    %{
      vendor_id: vendor.id,
      vendor_name: vendor.name,
      user_email: vendor.user.email,
      orders: %{
        total: order_count,
        active: active_order_count
      },
      menu_items: menu_item_count,
      order_items: order_item_count,
      user_will_be_deleted: !user_has_other_roles,
      has_active_orders: active_order_count > 0,
      # We can always delete, but UI can warn about active orders
      can_delete: true
    }
  end

  @doc """
  Archives a vendor instead of deleting (soft delete).
  This deactivates the vendor and all their menu items.
  """
  def archive_vendor(%Vendor{} = vendor) do
    Repo.transaction(fn ->
      # Deactivate vendor
      case Vendors.update_vendor(vendor, %{is_active: false}) do
        {:ok, updated_vendor} ->
          # Deactivate all menu items
          {count, _} =
            Repo.update_all(
              from(m in MenuItem, where: m.vendor_id == ^vendor.id),
              set: [is_available: false, updated_at: DateTime.utc_now()]
            )

          Logger.info("Archived vendor #{vendor.name} and deactivated #{count} menu items")

          %{
            vendor: updated_vendor,
            menu_items_deactivated: count
          }

        {:error, reason} ->
          Repo.rollback({:archive_failed, reason})
      end
    end)
  end
end
