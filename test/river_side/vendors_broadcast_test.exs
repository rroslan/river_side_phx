defmodule RiverSide.VendorsBroadcastTest do
  use RiverSide.DataCase
  import RiverSide.VendorsFixtures
  import RiverSide.AccountsFixtures

  alias RiverSide.Vendors

  describe "order broadcast functionality" do
    setup do
      user = user_fixture()
      vendor = vendor_fixture(%{user_id: user.id})
      menu_item = menu_item_fixture(%{vendor_id: vendor.id})

      %{vendor: vendor, menu_item: menu_item}
    end

    test "create_order/1 broadcasts to appropriate channels", %{
      vendor: vendor,
      menu_item: menu_item
    } do
      # Subscribe to all relevant channels
      phone = "1234567890"
      table_number = "5"

      Phoenix.PubSub.subscribe(RiverSide.PubSub, "vendor_orders:#{vendor.id}")
      Phoenix.PubSub.subscribe(RiverSide.PubSub, "orders:all")
      Phoenix.PubSub.subscribe(RiverSide.PubSub, "customer_session:#{phone}:#{table_number}")

      # Create order
      order_params = %{
        vendor_id: vendor.id,
        customer_phone: phone,
        customer_name: phone,
        table_number: table_number,
        order_items: [
          %{
            menu_item_id: menu_item.id,
            quantity: 2,
            price: menu_item.price
          }
        ]
      }

      # Create the order
      assert {:ok, order} = Vendors.create_order(order_params)

      # Verify broadcasts were sent to all channels
      assert_receive {:order_updated, received_order}, 1000
      assert received_order.id == order.id
      assert received_order.vendor_id == vendor.id

      # Should receive on vendor channel
      assert_receive {:order_updated, ^received_order}, 1000

      # Should receive on customer session channel
      assert_receive {:order_updated, ^received_order}, 1000

      # Should also receive on specific order channel
      Phoenix.PubSub.subscribe(RiverSide.PubSub, "order:#{order.id}")

      # Update the order to trigger another broadcast
      {:ok, _updated_order} = Vendors.update_order_status(order, %{status: "preparing"})

      assert_receive {:order_updated, updated_order}, 1000
      assert updated_order.status == "preparing"
    end

    test "create_order_with_items/2 broadcasts to appropriate channels", %{
      vendor: vendor,
      menu_item: menu_item
    } do
      # Subscribe to vendor channel
      Phoenix.PubSub.subscribe(RiverSide.PubSub, "vendor_orders:#{vendor.id}")

      # Create order using create_order_with_items
      order_attrs = %{
        vendor_id: vendor.id,
        customer_name: "9876543210",
        table_number: "3"
      }

      items = [
        %{
          menu_item_id: menu_item.id,
          quantity: 1
        }
      ]

      assert {:ok, order} = Vendors.create_order_with_items(order_attrs, items)

      # Verify broadcast was sent
      assert_receive {:order_updated, received_order}, 1000
      assert received_order.id == order.id
      assert received_order.vendor_id == vendor.id
      assert received_order.status == "pending"
    end

    test "vendor dashboard receives new order notifications", %{
      vendor: vendor,
      menu_item: menu_item
    } do
      # Simulate vendor dashboard subscription
      Phoenix.PubSub.subscribe(RiverSide.PubSub, "vendor_orders:#{vendor.id}")

      # Create multiple orders
      for i <- 1..3 do
        order_params = %{
          vendor_id: vendor.id,
          customer_phone: "555000#{i}",
          customer_name: "555000#{i}",
          table_number: "#{i}",
          order_items: [
            %{
              menu_item_id: menu_item.id,
              quantity: 1,
              price: menu_item.price
            }
          ]
        }

        {:ok, _order} = Vendors.create_order(order_params)

        # Should receive notification for each order
        assert_receive {:order_updated, order}, 1000
        assert order.table_number == "#{i}"
        assert order.status == "pending"
      end
    end

    test "customer receives updates for their session only", %{
      vendor: vendor,
      menu_item: menu_item
    } do
      # Customer 1 subscribes to their session
      customer1_phone = "1111111111"
      customer1_table = "1"

      Phoenix.PubSub.subscribe(
        RiverSide.PubSub,
        "customer_session:#{customer1_phone}:#{customer1_table}"
      )

      # Customer 2 has different session
      customer2_phone = "2222222222"
      customer2_table = "2"

      # Create order for customer 1
      order1_params = %{
        vendor_id: vendor.id,
        customer_phone: customer1_phone,
        customer_name: customer1_phone,
        table_number: customer1_table,
        order_items: [
          %{
            menu_item_id: menu_item.id,
            quantity: 1,
            price: menu_item.price
          }
        ]
      }

      {:ok, order1} = Vendors.create_order(order1_params)

      # Customer 1 should receive the update
      assert_receive {:order_updated, received_order}, 1000
      assert received_order.id == order1.id
      assert received_order.customer_name == customer1_phone

      # Create order for customer 2
      order2_params = %{
        vendor_id: vendor.id,
        customer_phone: customer2_phone,
        customer_name: customer2_phone,
        table_number: customer2_table,
        order_items: [
          %{
            menu_item_id: menu_item.id,
            quantity: 1,
            price: menu_item.price
          }
        ]
      }

      {:ok, order2} = Vendors.create_order(order2_params)

      # Customer 1 should NOT receive update for customer 2's order
      refute_receive {:order_updated, %{id: ^order2}}, 100
    end

    test "order status updates are broadcast correctly", %{vendor: vendor, menu_item: menu_item} do
      # Create an order first
      order_params = %{
        vendor_id: vendor.id,
        customer_phone: "7777777777",
        customer_name: "7777777777",
        table_number: "7",
        order_items: [
          %{
            menu_item_id: menu_item.id,
            quantity: 1,
            price: menu_item.price
          }
        ]
      }

      {:ok, order} = Vendors.create_order(order_params)

      # Subscribe to order-specific channel
      Phoenix.PubSub.subscribe(RiverSide.PubSub, "order:#{order.id}")

      # Update order status
      {:ok, _updated} = Vendors.update_order_status(order, %{status: "preparing"})

      assert_receive {:order_updated, updated_order}, 1000
      assert updated_order.id == order.id
      assert updated_order.status == "preparing"

      # Update to ready (need to reload order to get updated status)
      updated_order = Vendors.get_order!(order.id)
      {:ok, _updated} = Vendors.update_order_status(updated_order, %{status: "ready"})

      assert_receive {:order_updated, ready_order}, 1000
      assert ready_order.status == "ready"
    end
  end
end
