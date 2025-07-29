# Test script to verify order creation and broadcast timing
# Run with: mix run priv/scripts/test_order_broadcast_timing.exs

require Logger

# Get vendors
# First get the user, then the vendor
user = RiverSide.Accounts.get_user_by_email("roslanr@gmail.com")
drinks_vendor = RiverSide.Vendors.get_vendor_by_user_id(user.id)
Logger.info("Found drinks vendor: #{drinks_vendor.name}")

# Get a menu item
menu_items = RiverSide.Vendors.list_menu_items(drinks_vendor.id)
menu_item = List.first(menu_items)
Logger.info("Using menu item: #{menu_item.name} (RM#{menu_item.price})")

# Subscribe to PubSub channels to monitor broadcasts
Phoenix.PubSub.subscribe(RiverSide.PubSub, "vendor_orders:#{drinks_vendor.id}")
Phoenix.PubSub.subscribe(RiverSide.PubSub, "orders:all")

Logger.info("Subscribed to PubSub channels")

# Create spawn process to listen for broadcasts
_listener_pid = spawn(fn ->
  receive do
    {:order_updated, order} ->
      Logger.info("BROADCAST RECEIVED: Order ##{order.id} - Status: #{order.status}")
      Logger.info("Order details: Customer: #{order.customer_name}, Table: #{order.table_number}")
  after
    5000 ->
      Logger.error("No broadcast received within 5 seconds!")
  end
end)

# Create order with timing
Logger.info("Creating order...")
start_time = System.monotonic_time(:millisecond)

{status, result} = RiverSide.Vendors.create_order(%{
  vendor_id: drinks_vendor.id,
  customer_phone: "test_broadcast_123",
  customer_name: "test_broadcast_123",
  table_number: "99",
  order_items: [
    %{
      menu_item_id: menu_item.id,
      quantity: 2,
      price: menu_item.price
    }
  ]
})

end_time = System.monotonic_time(:millisecond)
duration = end_time - start_time

case status do
  :ok ->
    Logger.info("Order created successfully in #{duration}ms")
    Logger.info("Order ID: #{result.id}")
    Logger.info("Total: RM#{result.total_amount}")

    # Give the listener process time to receive the broadcast
    Process.sleep(1000)

    # Check if order exists in database
    fetched_order = RiverSide.Vendors.get_order!(result.id)
    Logger.info("Order verified in database: ##{fetched_order.id} with #{length(fetched_order.order_items)} items")

  :error ->
    Logger.error("Failed to create order: #{inspect(result)}")
end

# Wait a bit more to ensure all logs are printed
Process.sleep(100)

Logger.info("Test completed!")
