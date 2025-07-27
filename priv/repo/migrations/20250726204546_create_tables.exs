defmodule RiverSide.Repo.Migrations.CreateTables do
  use Ecto.Migration

  def change do
    create table(:tables) do
      add :number, :integer, null: false
      add :status, :string, default: "available"
      add :occupied_at, :utc_datetime
      add :customer_phone, :string
      add :customer_name, :string

      timestamps()
    end

    create unique_index(:tables, [:number])
    create index(:tables, [:status])
  end
end
