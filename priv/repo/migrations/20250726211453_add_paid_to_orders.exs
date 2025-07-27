defmodule RiverSide.Repo.Migrations.AddPaidToOrders do
  use Ecto.Migration

  def change do
    alter table(:orders) do
      add :paid, :boolean, default: false
      add :paid_at, :utc_datetime
    end
  end
end
