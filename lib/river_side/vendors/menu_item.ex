defmodule RiverSide.Vendors.MenuItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "menu_items" do
    field :name, :string
    field :description, :string
    field :price, :decimal
    field :category, :string
    field :image_url, :string
    field :is_available, :boolean, default: true

    belongs_to :vendor, RiverSide.Vendors.Vendor
    has_many :order_items, RiverSide.Vendors.OrderItem

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(menu_item, attrs) do
    menu_item
    |> cast(attrs, [:name, :description, :price, :category, :image_url, :is_available, :vendor_id])
    |> validate_required([:name, :price, :category, :vendor_id])
    |> validate_length(:name, min: 2, max: 100)
    |> validate_length(:description, max: 500)
    |> validate_number(:price, greater_than: 0, less_than: 10000)
    |> validate_inclusion(:category, ["food", "drinks"])
    |> foreign_key_constraint(:vendor_id)
  end

  @doc """
  Changeset for creating a menu item.
  """
  def create_changeset(menu_item, attrs) do
    menu_item
    |> cast(attrs, [:name, :description, :price, :category, :image_url, :vendor_id])
    |> validate_required([:name, :price, :category, :vendor_id])
    |> validate_length(:name, min: 2, max: 100)
    |> validate_length(:description, max: 500)
    |> validate_number(:price, greater_than: 0, less_than: 10000)
    |> validate_inclusion(:category, ["food", "drinks"])
    |> foreign_key_constraint(:vendor_id)
  end

  @doc """
  Changeset for updating a menu item including image.
  """
  def update_changeset(menu_item, attrs) do
    menu_item
    |> cast(attrs, [:name, :description, :price, :category, :image_url, :is_available])
    |> validate_required([:name, :price, :category])
    |> validate_length(:name, min: 2, max: 100)
    |> validate_length(:description, max: 500)
    |> validate_number(:price, greater_than: 0, less_than: 10000)
    |> validate_inclusion(:category, ["food", "drinks"])
  end

  @doc """
  Changeset for toggling availability.
  """
  def toggle_availability_changeset(menu_item, attrs) do
    menu_item
    |> cast(attrs, [:is_available])
    |> validate_required([:is_available])
  end
end
