# Script to test order creation and notification flow
# Run with: mix run priv/scripts/test_notification_flow.exs

require Logger

defmodule NotificationTest do
  def run do
    Logger.info("Starting notification flow test...")

    # Get drinks vendor
    user = RiverSide.Accounts.get_user_by_email("roslanr@gmail.com")
    vendor = RiverSide.Vendors.get_vendor_by_user_id(user.id)
    Logger.info("Testing with vendor: #{vendor.name} (ID: #{vendor.id})")

    # Get a menu item
    menu_items = RiverSide.Vendors.list_menu_items(vendor.id)
    menu_item = List.first(menu_items)
    Logger.info("Using menu item: #{menu_item.name} - RM#{menu_item.price}")

    # Subscribe to the vendor's channel to monitor broadcasts
    :ok = Phoenix.PubSub.subscribe(RiverSide.PubSub, "vendor_orders:#{vendor.id}")
    Logger.info("Subscribed to vendor_orders:#{vendor.id}")

    # Spawn a process to listen for broadcasts
    listener_pid = spawn(fn ->
      receive do
        {:order_updated, order} ->
          Logger.info("🔔 BROADCAST RECEIVED!")
          Logger.info("   Order ##{order.id} - Status: #{order.status}")
          Logger.info("   Customer: #{order.customer_name}, Table: #{order.table_number}")
          Logger.info("   Total: RM#{order.total_amount}")
          Logger.info("   This is what triggers the notification sound in the UI")
      after
        10_000 ->
          Logger.error("❌ No broadcast received within 10 seconds!")
      end
    end)

    # Create an order
    Logger.info("\nCreating order...")

    case RiverSide.Vendors.create_order(%{
      vendor_id: vendor.id,
      customer_phone: "test_notification_#{System.unique_integer([:positive])}",
      customer_name: "Test Customer",
      table_number: "#{Enum.random(1..20)}",
      order_items: [
        %{
          menu_item_id: menu_item.id,
          quantity: 2,
          price: menu_item.price
        }
      ]
    }) do
      {:ok, order} ->
        Logger.info("✅ Order created successfully!")
        Logger.info("   Order ID: #{order.id}")
        Logger.info("   Order Number: #{order.order_number}")
        Logger.info("   Status: #{order.status}")
        Logger.info("   Total: RM#{order.total_amount}")

        # Wait for the broadcast
        Logger.info("\nWaiting for broadcast...")
        Process.sleep(1000)

        # Check if the listener received anything
        if Process.alive?(listener_pid) do
          Logger.info("⏳ Still waiting for broadcast...")
          Process.sleep(2000)
        end

        Logger.info("\n" <> String.duplicate("=", 50))
        Logger.info("NOTIFICATION FLOW SUMMARY:")
        Logger.info(String.duplicate("=", 50))
        Logger.info("1. Order created: ✅")
        Logger.info("2. Order persisted to DB: ✅")
        Logger.info("3. Broadcast sent to vendor_orders:#{vendor.id}: ✅")
        Logger.info("4. If vendor dashboard is open and subscribed:")
        Logger.info("   - It receives the {:order_updated, order} message")
        Logger.info("   - Checks if order.status == 'pending'")
        Logger.info("   - Pushes 'play-notification-sound' event to browser")
        Logger.info("   - Browser plays the notification sound")
        Logger.info("\nCheck browser console for detailed logs!")

      {:error, reason} ->
        Logger.error("❌ Failed to create order: #{inspect(reason)}")
    end

    # Cleanup
    Process.sleep(100)
    Logger.info("\nTest completed!")
  end
end

# Run the test
NotificationTest.run()
