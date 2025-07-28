defmodule RiverSideWeb.CustomerFlowTest do
  use RiverSideWeb.ConnCase

  import Phoenix.LiveViewTest
  import RiverSide.VendorsFixtures
  import RiverSide.TablesFixtures

  describe "customer flow integration" do
    setup do
      # Create test data
      table = table_fixture(%{number: 10})
      vendor = vendor_fixture(%{name: "Test Vendor"})

      menu_item1 =
        menu_item_fixture(%{
          vendor_id: vendor.id,
          name: "Burger",
          price: Decimal.new("15.00"),
          category: "food"
        })

      menu_item2 =
        menu_item_fixture(%{
          vendor_id: vendor.id,
          name: "Coke",
          price: Decimal.new("3.50"),
          category: "drinks"
        })

      %{
        table: table,
        vendor: vendor,
        menu_item1: menu_item1,
        menu_item2: menu_item2
      }
    end

    test "complete customer flow from table selection to cart", %{
      conn: conn,
      table: table,
      vendor: vendor,
      menu_item1: menu_item1,
      menu_item2: menu_item2
    } do
      # Step 1: Start at table selection
      {:ok, index_live, _html} = live(conn, ~p"/")

      # Step 2: Click on table
      index_live
      |> element("#table-#{table.number}")
      |> render_click()

      # Should redirect to checkin
      assert_redirect(index_live, ~p"/customer/checkin/#{table.number}")

      # Step 3: Go to checkin page
      {:ok, checkin_live, _html} = live(conn, ~p"/customer/checkin/#{table.number}")

      # Step 4: Enter phone number
      checkin_live
      |> form("form", %{phone: "1234567890"})
      |> render_submit()

      # Should redirect to menu with params
      assert_redirect(checkin_live, ~p"/customer/menu?phone=1234567890&table=#{table.number}")

      # Step 5: Go to menu page
      {:ok, menu_live, html} =
        live(conn, ~p"/customer/menu?phone=1234567890&table=#{table.number}")

      # Verify vendor and items are shown
      assert html =~ vendor.name
      assert html =~ menu_item1.name
      assert html =~ "RM 15.00"
      assert html =~ menu_item2.name
      assert html =~ "RM 3.50"

      # Step 6: Add items to cart
      menu_live
      |> element("button[phx-click='add_to_cart'][phx-value-id='#{menu_item1.id}']")
      |> render_click()

      # Add same item again
      menu_live
      |> element("button[phx-click='add_to_cart'][phx-value-id='#{menu_item1.id}']")
      |> render_click()

      # Add different item
      menu_live
      |> element("button[phx-click='add_to_cart'][phx-value-id='#{menu_item2.id}']")
      |> render_click()

      # Verify cart button shows correct count and total
      html = render(menu_live)
      # Total items
      assert html =~ "3"
      # Total price (2 * 15.00 + 3.50)
      assert html =~ "RM 33.50"

      # Step 7: Click cart button
      cart_link =
        element(menu_live, "a[href='/customer/cart?phone=1234567890&table=#{table.number}']")

      assert cart_link

      # Navigate to cart
      {:ok, cart_live, html} =
        live(conn, ~p"/customer/cart?phone=1234567890&table=#{table.number}")

      # Verify cart contents
      assert html =~ "Your Cart"
      assert html =~ vendor.name
      assert html =~ menu_item1.name
      # Quantity for burger
      assert html =~ "2"
      assert html =~ menu_item2.name
      # Quantity for coke
      assert html =~ "1"
      # Total
      assert html =~ "RM 33.50"

      # Verify we can update quantities
      cart_live
      |> element(
        "button[phx-click='update_quantity'][phx-value-id='#{menu_item1.id}'][phx-value-action='increase']"
      )
      |> render_click()

      html = render(cart_live)
      # Updated quantity for burger
      assert html =~ "3"
      # Updated total (3 * 15.00 + 3.50)
      assert html =~ "RM 48.50"
    end

    test "cart navigation preserves customer info", %{conn: conn} do
      # Create table
      table = table_fixture(%{number: 5})

      # Create menu items
      vendor = vendor_fixture(%{name: "Test Vendor"})

      menu_item =
        menu_item_fixture(%{
          vendor_id: vendor.id,
          name: "Test Item",
          price: Decimal.new("10.00")
        })

      # Go directly to menu with params
      {:ok, menu_live, _html} =
        live(conn, ~p"/customer/menu?phone=9876543210&table=#{table.number}")

      # Add item to cart
      menu_live
      |> element("button[phx-click='add_to_cart'][phx-value-id='#{menu_item.id}']")
      |> render_click()

      # Navigate to cart
      {:ok, _cart_live, html} =
        live(conn, ~p"/customer/cart?phone=9876543210&table=#{table.number}")

      # Verify customer info is preserved
      assert html =~ "Table ##{table.number}"
      assert html =~ "Your Cart"
      assert html =~ menu_item.name
    end

    test "empty cart shows appropriate message", %{conn: conn} do
      table = table_fixture(%{number: 1})

      {:ok, _cart_live, html} =
        live(conn, ~p"/customer/cart?phone=1111111111&table=#{table.number}")

      assert html =~ "Your cart is empty"
      assert html =~ "Back to Menu"
    end

    test "cart requires phone and table params", %{conn: conn} do
      # Without params, should redirect to home
      assert {:error, {:live_redirect, %{to: "/"}}} = live(conn, ~p"/customer/cart")

      # With only phone
      assert {:error, {:live_redirect, %{to: "/"}}} =
               live(conn, ~p"/customer/cart?phone=1234567890")

      # With only table
      assert {:error, {:live_redirect, %{to: "/"}}} = live(conn, ~p"/customer/cart?table=5")
    end
  end
end
