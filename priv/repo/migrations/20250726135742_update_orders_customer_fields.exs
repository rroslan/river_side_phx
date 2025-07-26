defmodule RiverSide.Repo.Migrations.UpdateOrdersCustomerFields do
  use Ecto.Migration

  def change do
    alter table(:orders) do
      add :customer_name, :string
      modify :table_number, :string, from: :integer
    end
  end
end
