defmodule RiverSide.VendorsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `RiverSide.Vendors` context.
  """

  alias RiverSide.Vendors

  def unique_vendor_name, do: "vendor#{System.unique_integer()}"

  def valid_vendor_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      name: unique_vendor_name(),
      description: "Test vendor description",
      is_active: true
    })
  end

  def vendor_fixture(attrs \\ %{}) do
    # If no user_id is provided, create a vendor user first
    attrs =
      if Map.has_key?(attrs, :user_id) do
        attrs
      else
        user = RiverSide.AccountsFixtures.user_fixture(%{is_vendor: true})
        Map.put(attrs, :user_id, user.id)
      end

    {:ok, vendor} =
      attrs
      |> valid_vendor_attributes()
      |> Vendors.create_vendor()

    vendor
  end

  def menu_item_fixture(attrs \\ %{}) do
    vendor = Map.get(attrs, :vendor) || vendor_fixture()

    {:ok, menu_item} =
      attrs
      |> Enum.into(%{
        vendor_id: vendor.id,
        name: "Test Menu Item #{System.unique_integer()}",
        description: "Test menu item description",
        price: Decimal.new("10.50"),
        category: "food",
        is_available: true
      })
      |> Vendors.create_menu_item()

    menu_item
  end

  def order_fixture(attrs \\ %{}) do
    vendor = Map.get(attrs, :vendor) || vendor_fixture()

    {:ok, order} =
      attrs
      |> Enum.into(%{
        vendor_id: vendor.id,
        order_number: "ORD#{System.unique_integer([:positive])}",
        customer_name: "Test Customer",
        customer_phone: "0123456789",
        table_number: 1,
        status: "pending",
        total_amount: Decimal.new("10.50"),
        payment_status: "unpaid"
      })
      |> Vendors.create_order()

    order
  end

  def order_item_fixture(attrs \\ %{}) do
    order = Map.get(attrs, :order) || order_fixture()
    menu_item = Map.get(attrs, :menu_item) || menu_item_fixture(vendor: order.vendor)

    {:ok, order_item} =
      Vendors.create_order_item(
        %{
          order_id: order.id,
          menu_item_id: menu_item.id,
          quantity: attrs[:quantity] || 1,
          price: attrs[:price] || menu_item.price
        },
        menu_item
      )

    order_item
  end
end
