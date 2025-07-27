defmodule RiverSide.Vendors.Vendor do
  @moduledoc """
  Vendor schema representing food stalls in the River Side food court.

  Each vendor has their own menu items, orders, and can be managed by a user
  with the vendor role. Tracks vendor details like name, description, logo,
  and active status.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "vendors" do
    field :name, :string
    field :description, :string
    field :logo_url, :string
    field :is_active, :boolean, default: true

    belongs_to :user, RiverSide.Accounts.User
    has_many :menu_items, RiverSide.Vendors.MenuItem
    has_many :orders, RiverSide.Vendors.Order

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(vendor, attrs) do
    vendor
    |> cast(attrs, [:name, :description, :logo_url, :is_active, :user_id])
    |> validate_required([:name, :user_id])
    |> validate_length(:name, min: 2, max: 100)
    |> validate_length(:description, max: 500)
    |> unique_constraint(:user_id)
    |> foreign_key_constraint(:user_id)
  end

  @doc """
  Changeset for creating a vendor with a user association.
  """
  def create_changeset(vendor, attrs) do
    vendor
    |> cast(attrs, [:name, :description, :user_id])
    |> validate_required([:name, :user_id])
    |> validate_length(:name, min: 2, max: 100)
    |> validate_length(:description, max: 500)
    |> unique_constraint(:user_id)
    |> foreign_key_constraint(:user_id)
  end

  @doc """
  Changeset for updating vendor profile including logo.
  """
  def update_profile_changeset(vendor, attrs) do
    vendor
    |> cast(attrs, [:name, :description, :logo_url])
    |> validate_required([:name])
    |> validate_length(:name, min: 2, max: 100)
    |> validate_length(:description, max: 500)
  end

  @doc """
  Changeset for toggling vendor active status.
  """
  def toggle_active_changeset(vendor, attrs) do
    vendor
    |> cast(attrs, [:is_active])
    |> validate_required([:is_active])
  end
end
