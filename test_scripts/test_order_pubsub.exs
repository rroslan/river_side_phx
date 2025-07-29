# Test script to verify PubSub and order creation are working correctly
# Run with: mix run test_scripts/test_order_pubsub.exs

require Logger

# Get vendors
drinks_vendor = RiverSide.Vendors.list_vendors() |> Enum.find(&(&1.name == "Cool Drinks Corner"))
food_vendor = RiverSide.Vendors.list_vendors() |> Enum.find(&(&1.name == "Mama's Kitchen"))

if drinks_vendor && food_vendor do
  Logger.info("Found vendors: Drinks ID=#{drinks_vendor.id}, Food ID=#{food_vendor.id}")

  # Subscribe to vendor channels
  RiverSide.Vendors.subscribe_to_vendor_orders(drinks_vendor.id)
  RiverSide.Vendors.subscribe_to_vendor_orders(food_vendor.id)

  Logger.info("Subscribed to both vendor channels")

  # Create a test process that subscribes directly
  test_pid = self()

  # Spawn a process to listen for PubSub messages
  Task.start(fn ->
    Logger.info("PubSub listener started in separate process...")

    # Re-subscribe in this process since PubSub subscriptions are process-specific
    RiverSide.Vendors.subscribe_to_vendor_orders(drinks_vendor.id)
    RiverSide.Vendors.subscribe_to_vendor_orders(food_vendor.id)

    Logger.info("Re-subscribed to vendor channels in listener process")

    receive do
      {:order_updated, order} ->
        Logger.info("🔔 PubSub Message Received!")
        Logger.info("   Order ID: #{order.id}")
        Logger.info("   Order Number: #{order.order_number}")
        Logger.info("   Vendor ID: #{order.vendor_id}")
        Logger.info("   Status: #{order.status}")
        Logger.info("   Table: #{order.table_number}")
        Logger.info("   Customer: #{order.customer_name}")
        send(test_pid, :message_received)
    after
      10_000 ->
        Logger.info("No PubSub messages received after 10 seconds")
        send(test_pid, :timeout)
    end
  end)

  # Wait a moment for subscription to be ready
  Process.sleep(500)

  # Create a test order for drinks vendor
  Logger.info("\nCreating test order for drinks vendor...")

  drinks_items = RiverSide.Vendors.list_menu_items(drinks_vendor.id) |> Enum.take(2)

  order_params = %{
    vendor_id: drinks_vendor.id,
    customer_phone: "0123456789",
    customer_name: "0123456789",
    table_number: "99",
    order_items: Enum.map(drinks_items, fn item ->
      %{
        menu_item_id: item.id,
        quantity: 1,
        price: item.price
      }
    end)
  }

  case RiverSide.Vendors.create_order(order_params) do
    {:ok, order} ->
      Logger.info("✅ Order created successfully!")
      Logger.info("   Order Number: #{order.order_number}")
      Logger.info("   Total: RM#{order.total_amount}")

    {:error, changeset} ->
      Logger.error("❌ Failed to create order:")
      Logger.error(inspect(changeset.errors))
  end

  # Wait for PubSub message
  Process.sleep(2000)

  # Wait for response from listener
  receive do
    :message_received ->
      Logger.info("\n✅ PubSub is working correctly!")
    :timeout ->
      Logger.info("\n❌ PubSub timeout - messages not being received")
  after
    10_000 ->
      Logger.info("\n❌ Test timeout")
  end

else
  Logger.error("Could not find vendors. Please run mix ecto.setup first.")
end

Logger.info("\nTest completed.")
