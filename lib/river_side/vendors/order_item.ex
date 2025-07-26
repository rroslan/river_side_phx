defmodule RiverSide.Vendors.OrderItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "order_items" do
    field :quantity, :integer
    field :unit_price, :decimal
    field :subtotal, :decimal
    field :notes, :string

    belongs_to :order, RiverSide.Vendors.Order
    belongs_to :menu_item, RiverSide.Vendors.MenuItem

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(order_item, attrs) do
    order_item
    |> cast(attrs, [:quantity, :unit_price, :subtotal, :notes, :order_id, :menu_item_id])
    |> validate_required([:quantity, :unit_price, :subtotal, :order_id, :menu_item_id])
    |> validate_number(:quantity, greater_than: 0, less_than: 100)
    |> validate_number(:unit_price, greater_than: 0)
    |> validate_number(:subtotal, greater_than: 0)
    |> foreign_key_constraint(:order_id)
    |> foreign_key_constraint(:menu_item_id)
  end

  @doc """
  Changeset for creating an order item.
  """
  def create_changeset(order_item, attrs, menu_item) do
    order_item
    |> cast(attrs, [:quantity, :notes, :order_id, :menu_item_id])
    |> validate_required([:quantity, :order_id, :menu_item_id])
    |> validate_number(:quantity, greater_than: 0, less_than: 100)
    |> put_pricing(menu_item)
    |> foreign_key_constraint(:order_id)
    |> foreign_key_constraint(:menu_item_id)
  end

  @doc """
  Changeset for updating quantity.
  """
  def update_quantity_changeset(order_item, attrs) do
    order_item
    |> cast(attrs, [:quantity])
    |> validate_required([:quantity])
    |> validate_number(:quantity, greater_than: 0, less_than: 100)
    |> update_subtotal()
  end

  defp put_pricing(changeset, nil), do: changeset

  defp put_pricing(changeset, menu_item) do
    if changeset.valid? do
      quantity = get_field(changeset, :quantity)
      unit_price = menu_item.price
      subtotal = Decimal.mult(unit_price, quantity)

      changeset
      |> put_change(:unit_price, unit_price)
      |> put_change(:subtotal, subtotal)
    else
      changeset
    end
  end

  defp update_subtotal(changeset) do
    if changeset.valid? && get_change(changeset, :quantity) do
      quantity = get_field(changeset, :quantity)
      unit_price = get_field(changeset, :unit_price)
      subtotal = Decimal.mult(unit_price, quantity)

      put_change(changeset, :subtotal, subtotal)
    else
      changeset
    end
  end
end
