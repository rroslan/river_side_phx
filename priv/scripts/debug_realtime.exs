# Comprehensive Real-Time Debugging Script
# Run with: mix run priv/scripts/debug_realtime.exs

alias RiverSide.{Vendors, Repo, Accounts}
import Ecto.Query
require Logger

defmodule RealtimeDebugger do
  @moduledoc """
  Debug module to test PubSub and real-time updates
  """

  def run do
    Logger.info("=== Real-Time Updates Debugging ===")
    Logger.info("")

    # Step 1: Find Mama's Kitchen vendor
    vendor = find_mamas_kitchen()

    if vendor do
      # Step 2: Test PubSub directly
      test_pubsub(vendor)

      # Step 3: Create a test order with detailed logging
      create_test_order(vendor)

      # Step 4: Test order status update
      test_status_update(vendor)

      # Step 5: List current subscriptions
      list_subscriptions()
    else
      Logger.error("❌ Could not find Mama's Kitchen vendor")
    end

    Logger.info("")
    Logger.info("=== Debugging Complete ===")
  end

  defp find_mamas_kitchen do
    Logger.info("Step 1: Finding Mama's Kitchen vendor...")

    user = Repo.one(from u in Accounts.User, where: u.email == "vendor1@example.com")
    vendor = if user, do: Repo.one(from v in Vendors.Vendor, where: v.user_id == ^user.id)

    if vendor do
      Logger.info("✅ Found: #{vendor.name} (ID: #{vendor.id})")
      vendor
    else
      nil
    end
  end

  defp test_pubsub(vendor) do
    Logger.info("")
    Logger.info("Step 2: Testing PubSub directly...")

    # Subscribe to the vendor channel
    topic = "vendor_orders:#{vendor.id}"
    Logger.info("Subscribing to topic: #{topic}")

    case Phoenix.PubSub.subscribe(RiverSide.PubSub, topic) do
      :ok ->
        Logger.info("✅ Successfully subscribed to #{topic}")

        # Test broadcast
        Logger.info("Broadcasting test message...")
        Phoenix.PubSub.broadcast(
          RiverSide.PubSub,
          topic,
          {:test_message, "Hello from debugger!"}
        )

        # Check if we receive it
        receive do
          {:test_message, msg} ->
            Logger.info("✅ Received test message: #{msg}")
        after
          1000 ->
            Logger.error("❌ Did not receive test message within 1 second")
        end

      error ->
        Logger.error("❌ Failed to subscribe: #{inspect(error)}")
    end
  end

  defp create_test_order(vendor) do
    Logger.info("")
    Logger.info("Step 3: Creating test order with detailed logging...")

    # Get a menu item
    menu_item =
      Vendors.list_menu_items(vendor.id)
      |> Enum.filter(& &1.is_available)
      |> List.first()

    if menu_item do
      Logger.info("Using menu item: #{menu_item.name}")

      # Subscribe to vendor orders before creating
      topic = "vendor_orders:#{vendor.id}"
      Phoenix.PubSub.subscribe(RiverSide.PubSub, topic)
      Logger.info("Subscribed to #{topic} to monitor broadcast")

      order_params = %{
        vendor_id: vendor.id,
        customer_phone: "5559999999",
        customer_name: "5559999999",
        table_number: "99",
        order_items: [
          %{
            menu_item_id: menu_item.id,
            quantity: 1,
            price: menu_item.price
          }
        ]
      }

      Logger.info("Creating order...")

      case Vendors.create_order(order_params) do
        {:ok, order} ->
          Logger.info("✅ Order created: #{order.order_number}")

          # Wait for broadcast
          receive do
            {:order_updated, received_order} ->
              Logger.info("✅ Received order broadcast!")
              Logger.info("   Order ID: #{received_order.id}")
              Logger.info("   Status: #{received_order.status}")
              Logger.info("   Vendor ID: #{received_order.vendor_id}")
          after
            2000 ->
              Logger.error("❌ Did not receive order broadcast within 2 seconds")
          end

          order

        {:error, changeset} ->
          Logger.error("❌ Failed to create order: #{inspect(changeset.errors)}")
          nil
      end
    else
      Logger.error("❌ No available menu items")
      nil
    end
  end

  defp test_status_update(vendor) do
    Logger.info("")
    Logger.info("Step 4: Testing order status update...")

    # Get most recent order
    order =
      Repo.one(
        from o in Vendors.Order,
        where: o.vendor_id == ^vendor.id and o.status == "pending",
        order_by: [desc: o.inserted_at],
        limit: 1
      )

    if order do
      Logger.info("Updating order #{order.order_number} to 'preparing'...")

      # Subscribe to order-specific channel
      Phoenix.PubSub.subscribe(RiverSide.PubSub, "order:#{order.id}")

      case Vendors.update_order_status(order, %{status: "preparing"}) do
        {:ok, updated} ->
          Logger.info("✅ Order updated successfully")

          # Wait for broadcast
          receive do
            {:order_updated, received_order} ->
              Logger.info("✅ Received status update broadcast!")
              Logger.info("   New status: #{received_order.status}")
          after
            2000 ->
              Logger.error("❌ Did not receive status update broadcast")
          end

        {:error, _} ->
          Logger.error("❌ Failed to update order status")
      end
    else
      Logger.info("No pending orders to update")
    end
  end

  defp list_subscriptions do
    Logger.info("")
    Logger.info("Step 5: Checking PubSub state...")

    # Get PubSub state
    try do
      # This is Phoenix.PubSub internal, might not work in all versions
      {:ok, registry} = Registry.start_link(keys: :duplicate, name: :test_registry)
      Logger.info("PubSub appears to be running")

      # Check if we can see any subscriptions
      Process.list()
      |> Enum.filter(fn pid ->
        case Process.info(pid, :registered_name) do
          {:registered_name, name} when is_atom(name) ->
            String.contains?(to_string(name), "PubSub")
          _ ->
            false
        end
      end)
      |> Enum.each(fn pid ->
        Logger.info("Found PubSub process: #{inspect(pid)}")
      end)

    catch
      _, _ ->
        Logger.info("Could not inspect PubSub internals")
    end
  end
end

# Run the debugger
RealtimeDebugger.run()

# Additional manual test
Logger.info("")
Logger.info("=== Manual Broadcast Test ===")
Logger.info("Broadcasting to vendor_orders:18 in 3 seconds...")
Process.sleep(3000)

# Manually broadcast an order update
test_order = %{
  id: 999,
  order_number: "TEST-ORDER",
  status: "pending",
  vendor_id: 18,
  table_number: "TEST",
  customer_name: "TEST",
  total_amount: Decimal.new("10.00"),
  vendor: %{name: "Mama's Kitchen"},
  order_items: []
}

Phoenix.PubSub.broadcast(
  RiverSide.PubSub,
  "vendor_orders:18",
  {:order_updated, test_order}
)

Logger.info("✅ Manual broadcast sent")
Logger.info("")
Logger.info("Check your Mama's Kitchen dashboard now!")
Logger.info("You should see:")
Logger.info("  1. A flash message about a new order")
Logger.info("  2. Browser console logs about receiving the order")
Logger.info("")
Logger.info("If nothing appears, check:")
Logger.info("  1. Browser console for WebSocket errors")
Logger.info("  2. Network tab for WS connection status")
Logger.info("  3. Server logs for any errors")
