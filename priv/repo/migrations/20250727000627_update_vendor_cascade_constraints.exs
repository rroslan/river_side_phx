defmodule RiverSide.Repo.Migrations.UpdateVendorCascadeConstraints do
  use Ecto.Migration

  def up do
    # Drop existing foreign key constraints
    drop constraint(:orders, "orders_vendor_id_fkey")
    drop constraint(:order_items, "order_items_menu_item_id_fkey")

    # Recreate with cascade delete for orders when vendor is deleted
    alter table(:orders) do
      modify :vendor_id, references(:vendors, on_delete: :delete_all), null: false
    end

    # Recreate with cascade delete for order_items when menu_item is deleted
    alter table(:order_items) do
      modify :menu_item_id, references(:menu_items, on_delete: :delete_all), null: false
    end
  end

  def down do
    # Drop the new constraints
    drop constraint(:orders, "orders_vendor_id_fkey")
    drop constraint(:order_items, "order_items_menu_item_id_fkey")

    # Restore original constraints
    alter table(:orders) do
      modify :vendor_id, references(:vendors, on_delete: :restrict), null: false
    end

    alter table(:order_items) do
      modify :menu_item_id, references(:menu_items, on_delete: :restrict), null: false
    end
  end
end
