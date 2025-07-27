defmodule RiverSide.Vendors.Order do
  @moduledoc """
  Order schema for managing customer orders in the food court system.

  Tracks order lifecycle from pending through completion, including payment status
  and relationships to vendors, customers, and order items.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias RiverSideWeb.Helpers.TimezoneHelper

  schema "orders" do
    field :order_number, :string
    field :customer_name, :string
    field :table_number, :string
    field :status, :string, default: "pending"
    field :total_amount, :decimal
    field :notes, :string
    field :paid, :boolean, default: false
    field :paid_at, :utc_datetime

    belongs_to :vendor, RiverSide.Vendors.Vendor
    belongs_to :cashier, RiverSide.Accounts.User
    has_many :order_items, RiverSide.Vendors.OrderItem

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(order, attrs) do
    order
    |> cast(attrs, [
      :order_number,
      :customer_name,
      :table_number,
      :status,
      :total_amount,
      :notes,
      :vendor_id,
      :cashier_id,
      :paid,
      :paid_at
    ])
    |> validate_required([:order_number, :status, :total_amount, :vendor_id])
    |> validate_number(:total_amount, greater_than_or_equal_to: 0)
    |> validate_inclusion(:status, ["pending", "preparing", "ready", "completed", "cancelled"])
    |> unique_constraint(:order_number)
    |> foreign_key_constraint(:vendor_id)
    |> foreign_key_constraint(:cashier_id)
  end

  @doc """
  Changeset for creating a new order.
  """
  def create_changeset(order, attrs) do
    order
    |> cast(attrs, [:customer_name, :table_number, :notes, :vendor_id, :cashier_id])
    |> validate_required([:customer_name, :vendor_id])
    |> put_order_number()
    |> put_change(:status, "pending")
    |> put_change(:total_amount, Decimal.new("0.00"))
    |> foreign_key_constraint(:vendor_id)
    |> foreign_key_constraint(:cashier_id)
  end

  @doc """
  Changeset for updating order status.
  """
  def update_status_changeset(order, attrs) do
    order
    |> cast(attrs, [:status])
    |> validate_required([:status])
    |> validate_inclusion(:status, ["pending", "preparing", "ready", "completed", "cancelled"])
    |> validate_status_transition()
  end

  @doc """
  Changeset for updating order total.
  """
  def update_total_changeset(order, attrs) do
    order
    |> cast(attrs, [:total_amount])
    |> validate_required([:total_amount])
    |> validate_number(:total_amount, greater_than_or_equal_to: 0)
  end

  @doc """
  Changeset for marking an order as paid.
  """
  def mark_as_paid_changeset(order) do
    order
    |> change()
    |> put_change(:paid, true)
    |> put_change(:paid_at, DateTime.utc_now() |> DateTime.truncate(:second))
  end

  defp put_order_number(changeset) do
    if changeset.valid? do
      # Generate order number: ORD-YYYYMMDD-XXXXX using Malaysian date
      date = TimezoneHelper.malaysian_today() |> Calendar.strftime("%Y%m%d")
      random = :crypto.strong_rand_bytes(3) |> Base.encode16()
      order_number = "ORD-#{date}-#{random}"
      put_change(changeset, :order_number, order_number)
    else
      changeset
    end
  end

  defp validate_status_transition(changeset) do
    if changeset.valid? && get_change(changeset, :status) do
      old_status = changeset.data.status
      new_status = get_change(changeset, :status)

      valid_transition? =
        case {old_status, new_status} do
          {_, same} when same == old_status -> true
          {"pending", "preparing"} -> true
          {"pending", "cancelled"} -> true
          {"preparing", "ready"} -> true
          {"preparing", "cancelled"} -> true
          {"ready", "completed"} -> true
          {"ready", "cancelled"} -> true
          _ -> false
        end

      if valid_transition? do
        changeset
      else
        add_error(
          changeset,
          :status,
          "invalid status transition from #{old_status} to #{new_status}"
        )
      end
    else
      changeset
    end
  end
end
