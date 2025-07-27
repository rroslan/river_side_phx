defmodule RiverSide.Vendors.OrderItem do
  @moduledoc """
  Order item schema representing individual items within an order.

  Each order item tracks a specific menu item ordered by a customer,
  including quantity, pricing, and any special notes. The subtotal
  is automatically calculated based on quantity and unit price.

  ## Fields

  * `:quantity` - Number of units ordered (1-99)
  * `:unit_price` - Price per unit at time of order
  * `:subtotal` - Total price for this line item (quantity × unit_price)
  * `:notes` - Optional special instructions from customer
  * `:order_id` - Reference to parent order
  * `:menu_item_id` - Reference to the menu item ordered

  ## Business Rules

  * Quantity must be between 1 and 99
  * Prices are captured at order time to handle menu price changes
  * Subtotal is automatically calculated and updated
  * Order items cannot be modified after order is completed
  """
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

  @doc """
  Generic changeset for order item updates.

  Validates all fields and enforces business rules. This changeset
  is primarily used for administrative updates and data migrations.

  ## Parameters

  * `order_item` - The order item struct
  * `attrs` - Map of attributes to update

  ## Validations

  * All required fields must be present
  * Quantity must be between 1 and 99
  * Prices must be positive
  * Foreign key constraints are enforced
  """
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
  Changeset for creating an order item with automatic pricing.

  Used when customers add items to their cart. Automatically sets
  the unit price and calculates subtotal based on the current menu
  item price and requested quantity.

  ## Parameters

  * `order_item` - New order item struct
  * `attrs` - Map containing `:quantity`, `:notes`, `:order_id`, `:menu_item_id`
  * `menu_item` - The menu item being ordered (for pricing)

  ## Examples

      iex> create_changeset(%OrderItem{}, %{quantity: 2, notes: "Extra spicy"}, menu_item)
      %Ecto.Changeset{valid?: true}
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
  Changeset for updating order item quantity.

  Used when customers modify quantities in their cart. Automatically
  recalculates the subtotal based on the new quantity while preserving
  the original unit price.

  ## Parameters

  * `order_item` - Existing order item to update
  * `attrs` - Map containing new `:quantity`

  ## Notes

  * Unit price remains unchanged (captured at creation time)
  * Subtotal is automatically recalculated
  * Can only be used on pending orders
  """
  def update_quantity_changeset(order_item, attrs) do
    order_item
    |> cast(attrs, [:quantity])
    |> validate_required([:quantity])
    |> validate_number(:quantity, greater_than: 0, less_than: 100)
    |> update_subtotal()
  end

  # Sets pricing information from the menu item
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

  # Recalculates subtotal when quantity changes
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
