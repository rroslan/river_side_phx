# Simple test to add one order to Mama's Kitchen with clear debugging
# Run with: mix run priv/scripts/test_single_order.exs

alias RiverSide.{Vendors, Repo}
import Ecto.Query
require Logger

Logger.info("=== Single Order Test for Real-Time Updates ===")
Logger.info("")

# Find Mama's Kitchen
vendor = Repo.one(from v in Vendors.Vendor, where: v.id == 18)

if vendor do
  Logger.info("Testing with vendor: #{vendor.name} (ID: #{vendor.id})")

  # Get first available menu item
  menu_item =
    Vendors.list_menu_items(vendor.id)
    |> Enum.filter(& &1.is_available)
    |> List.first()

  if menu_item do
    Logger.info("Using menu item: #{menu_item.name} @ RM#{menu_item.price}")
    Logger.info("")
    Logger.info("Creating order in 3 seconds...")
    Logger.info("Watch your Mama's Kitchen dashboard for:")
    Logger.info("  1. Green border flash at top of page")
    Logger.info("  2. Console logs showing 'VendorDashboard: Received debug update'")
    Logger.info("  3. Flash message about new order")
    Logger.info("  4. Order appearing in active orders list")
    Logger.info("")

    Process.sleep(3000)

    # Create order with unique table number to identify it
    timestamp = DateTime.utc_now() |> DateTime.to_unix()
    table_number = "TEST-#{rem(timestamp, 1000)}"

    order_params = %{
      vendor_id: vendor.id,
      customer_phone: "5559999999",
      customer_name: "5559999999",
      table_number: table_number,
      order_items: [
        %{
          menu_item_id: menu_item.id,
          quantity: 2,
          price: menu_item.price
        }
      ]
    }

    Logger.info("Creating order for Table #{table_number}...")

    case Vendors.create_order(order_params) do
      {:ok, order} ->
        Logger.info("")
        Logger.info("✅ Order created successfully!")
        Logger.info("   Order Number: #{order.order_number}")
        Logger.info("   Table: #{order.table_number}")
        Logger.info("   Total: RM#{order.total_amount}")
        Logger.info("")
        Logger.info("📋 Check your browser console for these logs:")
        Logger.info("   - 'VendorDashboard: Received debug update'")
        Logger.info("   - 'Order count: X'")
        Logger.info("   - 'Timestamp: YYYY-MM-DD...'")
        Logger.info("")
        Logger.info("🔍 If order doesn't appear:")
        Logger.info("   1. Check browser console for errors")
        Logger.info("   2. Try clicking 'Enable Sound' button")
        Logger.info("   3. Check Network tab for WebSocket connection")
        Logger.info("   4. Look for 'Vendor Dashboard: Received order update' in server logs")

      {:error, changeset} ->
        Logger.error("❌ Failed to create order: #{inspect(changeset.errors)}")
    end
  else
    Logger.error("❌ No available menu items found")
  end
else
  Logger.error("❌ Mama's Kitchen vendor not found")
end

Logger.info("")
Logger.info("=== Test Complete ===")
