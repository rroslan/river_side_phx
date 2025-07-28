defmodule RiverSide.TablesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `RiverSide.Tables` context.
  """

  @doc """
  Generate a table.
  """
  def table_fixture(attrs \\ %{}) do
    {:ok, table} =
      attrs
      |> Enum.into(%{
        number: rem(System.unique_integer([:positive]), 1000) + 1,
        status: "available",
        cart: %{}
      })
      |> RiverSide.Tables.create_table()

    table
  end

  @doc """
  Generate a unique table number.
  """
  def unique_table_number, do: rem(System.unique_integer([:positive]), 1000) + 1
end
