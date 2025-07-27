defmodule RiverSide.Tables.Table do
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

  @doc false
  def changeset(table, attrs) do
    table
    |> cast(attrs, [:number, :status, :occupied_at, :customer_phone, :customer_name, :cart_data])
    |> validate_required([:number, :status])
    |> validate_inclusion(:status, ["available", "occupied", "reserved"])
    |> unique_constraint(:number)
  end

  @doc """
  Changeset for occupying a table.
  """
  def occupy_changeset(table, attrs) do
    table
    |> cast(attrs, [:customer_phone, :customer_name])
    |> validate_required([:customer_phone])
    |> put_change(:status, "occupied")
    |> put_change(:occupied_at, DateTime.utc_now() |> DateTime.truncate(:second))
  end

  @doc """
  Changeset for releasing a table.
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
