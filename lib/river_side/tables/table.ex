defmodule RiverSide.Tables.Table do
  @moduledoc """
  Table schema representing physical tables in the River Side food court.

  Tables are used for customer seating and order management. Each table
  can be occupied by customers who can place orders through the system.
  The table tracks occupancy status, customer information, and maintains
  a shopping cart for the current session.

  ## Fields

  * `:number` - Unique table identifier displayed to customers
  * `:status` - Current table state: "available", "occupied", or "reserved"
  * `:occupied_at` - Timestamp when table was last occupied
  * `:customer_phone` - Phone number of current customer (for order tracking)
  * `:customer_name` - Optional name of current customer
  * `:cart_data` - Shopping cart data stored as a map

  ## Status Flow

      available -> occupied (customer checks in)
      occupied -> available (customer checks out or timeout)
      available -> reserved (future feature)

  ## Cart Management

  The cart_data field stores the customer's current shopping cart,
  allowing them to browse and add items from multiple vendors before
  placing their final order.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "tables" do
    field :number, :integer
    field :status, :string, default: "available"
    field :occupied_at, :utc_datetime
    field :customer_phone, :string
    field :customer_name, :string
    field :cart_data, :map, default: %{}

    timestamps()
  end

  @doc """
  Generic changeset for table updates.

  Validates all fields and enforces business rules. This changeset
  is primarily used for administrative updates.

  ## Parameters

  * `table` - The table struct
  * `attrs` - Map of attributes to update

  ## Validations

  * Table number must be unique
  * Status must be one of: "available", "occupied", "reserved"
  * Required fields: number, status
  """
  def changeset(table, attrs) do
    table
    |> cast(attrs, [:number, :status, :occupied_at, :customer_phone, :customer_name, :cart_data])
    |> validate_required([:number, :status])
    |> validate_inclusion(:status, ["available", "occupied", "reserved"])
    |> unique_constraint(:number)
  end

  @doc """
  Changeset for occupying a table when a customer checks in.

  Sets the table status to "occupied", records the occupation time,
  and stores customer information for order tracking.

  ## Parameters

  * `table` - Available table to occupy
  * `attrs` - Map containing `:customer_phone` (required) and `:customer_name` (optional)

  ## Side Effects

  * Sets status to "occupied"
  * Sets occupied_at to current UTC time
  * Clears any previous cart data

  ## Examples

      iex> occupy_changeset(table, %{customer_phone: "0123456789", customer_name: "John"})
      %Ecto.Changeset{valid?: true}
  """
  def occupy_changeset(table, attrs) do
    table
    |> cast(attrs, [:customer_phone, :customer_name])
    |> validate_required([:customer_phone])
    |> put_change(:status, "occupied")
    |> put_change(:occupied_at, DateTime.utc_now() |> DateTime.truncate(:second))
  end

  @doc """
  Changeset for releasing a table back to available status.

  Clears all customer data and resets the table to its initial state.
  Used when customers check out, complete their dining, or when
  tables are manually released by staff.

  ## Parameters

  * `table` - Occupied table to release

  ## Side Effects

  * Sets status to "available"
  * Clears occupied_at timestamp
  * Removes all customer information
  * Empties the cart data

  ## Notes

  This operation should be called after all pending orders for the
  table have been completed or cancelled.
  """
  def release_changeset(table) do
    table
    |> change()
    |> put_change(:status, "available")
    |> put_change(:occupied_at, nil)
    |> put_change(:customer_phone, nil)
    |> put_change(:customer_name, nil)
    |> put_change(:cart_data, %{})
  end
end
