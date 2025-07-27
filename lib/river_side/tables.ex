defmodule RiverSide.Tables do
  @moduledoc """
  The Tables context.
  """

  import Ecto.Query, warn: false
  alias RiverSide.Repo
  alias RiverSide.Tables.Table

  @doc """
  Returns the list of tables.
  """
  def list_tables do
    Repo.all(from t in Table, order_by: t.number)
  end

  @doc """
  Gets a single table.

  Raises `Ecto.NoResultsError` if the Table does not exist.
  """
  def get_table!(id), do: Repo.get!(Table, id)

  @doc """
  Gets a table by number.
  """
  def get_table_by_number(number) do
    Repo.get_by(Table, number: number)
  end

  @doc """
  Gets a table by number, raises if not found.
  """
  def get_table_by_number!(number) do
    Repo.get_by!(Table, number: number)
  end

  @doc """
  Creates a table.
  """
  def create_table(attrs \\ %{}) do
    %Table{}
    |> Table.changeset(attrs)
    |> Repo.insert()
    |> broadcast_table_update()
  end

  @doc """
  Updates a table.
  """
  def update_table(%Table{} = table, attrs) do
    table
    |> Table.changeset(attrs)
    |> Repo.update()
    |> broadcast_table_update()
  end

  @doc """
  Occupies a table with customer information.
  """
  def occupy_table(%Table{} = table, attrs) do
    table
    |> Table.occupy_changeset(attrs)
    |> Repo.update()
    |> broadcast_table_update()
  end

  @doc """
  Releases a table, making it available again.
  """
  def release_table(%Table{} = table) do
    table
    |> Table.release_changeset()
    |> Repo.update()
    |> broadcast_table_update()
  end

  @doc """
  Deletes a table.
  """
  def delete_table(%Table{} = table) do
    Repo.delete(table)
    |> broadcast_table_update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking table changes.
  """
  def change_table(%Table{} = table, attrs \\ %{}) do
    Table.changeset(table, attrs)
  end

  @doc """
  Initializes tables 1-20 if they don't exist.
  """
  def initialize_tables do
    existing_numbers =
      Repo.all(from t in Table, select: t.number)
      |> MapSet.new()

    results =
      1..20
      |> Enum.reject(&MapSet.member?(existing_numbers, &1))
      |> Enum.map(fn number ->
        create_table(%{number: number, status: "available"})
      end)

    {:ok, length(results)}
  end

  @doc """
  Resets all tables to available status.
  """
  def reset_all_tables do
    from(t in Table, where: t.status != "available")
    |> Repo.update_all(
      set: [
        status: "available",
        occupied_at: nil,
        customer_phone: nil,
        customer_name: nil,
        cart_data: %{},
        updated_at: DateTime.utc_now() |> DateTime.truncate(:second)
      ]
    )

    broadcast_tables_reset()
  end

  @doc """
  Gets table statistics.
  """
  def get_table_stats do
    tables = list_tables()

    %{
      total: length(tables),
      available: Enum.count(tables, &(&1.status == "available")),
      occupied: Enum.count(tables, &(&1.status == "occupied")),
      reserved: Enum.count(tables, &(&1.status == "reserved"))
    }
  end

  @doc """
  Updates the cart data for a table.
  """
  def update_table_cart(%Table{} = table, cart_data) do
    table
    |> Table.changeset(%{cart_data: cart_data})
    |> Repo.update()
    |> broadcast_table_update()
  end

  @doc """
  Gets the cart data for a table.
  """
  def get_table_cart(%Table{} = table) do
    table.cart_data || %{}
  end

  @doc """
  Adds an item to the table's cart.
  """
  def add_to_cart(%Table{} = table, item_id, quantity \\ 1) do
    cart_data = get_table_cart(table)
    item_key = to_string(item_id)
    current_qty = Map.get(cart_data, item_key, 0)
    updated_cart = Map.put(cart_data, item_key, current_qty + quantity)

    update_table_cart(table, updated_cart)
  end

  @doc """
  Removes an item from the table's cart.
  """
  def remove_from_cart(%Table{} = table, item_id) do
    cart_data = get_table_cart(table)
    item_key = to_string(item_id)
    updated_cart = Map.delete(cart_data, item_key)

    update_table_cart(table, updated_cart)
  end

  @doc """
  Updates the quantity of an item in the table's cart.
  """
  def update_cart_item(%Table{} = table, item_id, quantity) do
    cart_data = get_table_cart(table)
    item_key = to_string(item_id)

    updated_cart =
      if quantity > 0 do
        Map.put(cart_data, item_key, quantity)
      else
        Map.delete(cart_data, item_key)
      end

    update_table_cart(table, updated_cart)
  end

  @doc """
  Clears the cart for a table.
  """
  def clear_cart(%Table{} = table) do
    update_table_cart(table, %{})
  end

  # PubSub functions

  @topic "tables"

  def subscribe do
    Phoenix.PubSub.subscribe(RiverSide.PubSub, @topic)
  end

  def subscribe_to_table(table_number) do
    Phoenix.PubSub.subscribe(RiverSide.PubSub, "#{@topic}:#{table_number}")
  end

  defp broadcast_table_update({:ok, table} = result) do
    Phoenix.PubSub.broadcast(RiverSide.PubSub, @topic, {:table_updated, table})

    Phoenix.PubSub.broadcast(
      RiverSide.PubSub,
      "#{@topic}:#{table.number}",
      {:table_updated, table}
    )

    result
  end

  defp broadcast_table_update({:error, _} = error), do: error

  defp broadcast_tables_reset do
    Phoenix.PubSub.broadcast(RiverSide.PubSub, @topic, :tables_reset)
    :ok
  end
end
