defmodule RiverSide.Repo.Migrations.CreateVendorsAndMenus do
  use Ecto.Migration

  def change do
    # Create vendors table
    create table(:vendors) do
      add :name, :string, null: false
      add :description, :text
      add :logo_url, :string
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :is_active, :boolean, default: true, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:vendors, [:user_id])
    create index(:vendors, [:is_active])

    # Create menu_items table
    create table(:menu_items) do
      add :name, :string, null: false
      add :description, :text
      add :price, :decimal, precision: 10, scale: 2, null: false
      # "food" or "drinks"
      add :category, :string, null: false
      add :image_url, :string
      add :is_available, :boolean, default: true, null: false
      add :vendor_id, references(:vendors, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:menu_items, [:vendor_id])
    create index(:menu_items, [:category])
    create index(:menu_items, [:is_available])

    # Create orders table
    create table(:orders) do
      add :order_number, :string, null: false
      add :table_number, :integer, null: false
      # pending, preparing, ready, completed, cancelled
      add :status, :string, default: "pending", null: false
      add :total_amount, :decimal, precision: 10, scale: 2, null: false
      add :notes, :text
      add :vendor_id, references(:vendors, on_delete: :restrict), null: false
      add :cashier_id, references(:users, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:orders, [:order_number])
    create index(:orders, [:vendor_id])
    create index(:orders, [:status])
    create index(:orders, [:table_number])
    create index(:orders, [:inserted_at])

    # Create order_items table
    create table(:order_items) do
      add :quantity, :integer, null: false
      add :unit_price, :decimal, precision: 10, scale: 2, null: false
      add :subtotal, :decimal, precision: 10, scale: 2, null: false
      add :notes, :text
      add :order_id, references(:orders, on_delete: :delete_all), null: false
      add :menu_item_id, references(:menu_items, on_delete: :restrict), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:order_items, [:order_id])
    create index(:order_items, [:menu_item_id])
  end
end
