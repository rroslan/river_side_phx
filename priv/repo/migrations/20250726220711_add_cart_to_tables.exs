defmodule RiverSide.Repo.Migrations.AddCartToTables do
  use Ecto.Migration

  def change do
    alter table(:tables) do
      add :cart_data, :map, default: %{}
    end
  end
end
