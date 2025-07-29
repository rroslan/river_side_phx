# Script to add test orders to multiple vendors for comprehensive testing
# Run with: mix run priv/scripts/add_multiple_test_orders.exs

alias RiverSide.{Vendors, Repo}
import Ecto.Query
require Logger

# Configuration
test_tables = ["1", "2", "3", "5", "10"]
test_phones = ["5551234567", "5559876543", "5555555555", "5551111111", "5552222222"]

Logger.info("=== Adding Multiple Test Orders ===")
Logger.info("This will add orders to all active vendors from different tables")
Logger.info("")

# Get all active vendors
vendors =
  Repo.all(Vendors.Vendor)
  |> Enum.filter(& &1.is_active)
  |> Enum.take(5)  # Limit to 5 vendors for testing

if Enum.empty?(vendors) do
  Logger.error("❌ No active vendors found in the system")
  Logger.info("Please ensure at least one vendor is active.")
else
  Logger.info("Found #{length(vendors)} active vendor(s)")
  Logger.info("")

  # Create orders for each vendor
  Enum.with_index(vendors)
  |> Enum.each(fn {vendor, index} ->
    # Get available menu items for this vendor
    menu_items =
      Vendors.list_menu_items(vendor.id)
      |> Enum.filter(& &1.is_available)
      |> Enum.take(3)  # Get up to 3 items

    if Enum.empty?(menu_items) do
      Logger.warning("⚠️  No available menu items for #{vendor.name}, skipping...")
    else
      # Use rotating table and phone numbers
      table_number = Enum.at(test_tables, rem(index, length(test_tables)))
      customer_phone = Enum.at(test_phones, rem(index, length(test_phones)))

      Logger.info("📍 Creating order for #{vendor.name} (ID: #{vendor.id})")
      Logger.info("   Table: #{table_number}, Phone: #{customer_phone}")

      # Build order items from available menu items
      order_items =
        menu_items
        |> Enum.take(Enum.random(1..2))  # Random 1-2 items per order
        |> Enum.map(fn item ->
          %{
            menu_item_id: item.id,
            quantity: Enum.random(1..3),
            price: item.price
          }
        end)

      # Create the order
      order_params = %{
        vendor_id: vendor.id,
        customer_phone: customer_phone,
        customer_name: customer_phone,
        table_number: table_number,
        order_items: order_items
      }

      case Vendors.create_order(order_params) do
        {:ok, order} ->
          total_items = Enum.sum(Enum.map(order_items, & &1.quantity))
          Logger.info("   ✅ Order #{order.order_number} created")
          Logger.info("      Items: #{length(order_items)}, Quantity: #{total_items}, Total: RM#{order.total_amount}")

        {:error, changeset} ->
          Logger.error("   ❌ Failed to create order:")
          Logger.error("      #{inspect(changeset.errors)}")
      end

      # Small delay to simulate realistic order timing
      Process.sleep(500)
    end

    Logger.info("")
  end)

  Logger.info("=== Summary ===")
  Logger.info("Check all vendor dashboards for:")
  Logger.info("  - Flash notifications")
  Logger.info("  - New orders in active orders list")
  Logger.info("  - Real-time updates working")
  Logger.info("")
  Logger.info("Also check customer order tracking pages for:")
  Logger.info("  - Multiple orders showing for same table/phone")
  Logger.info("  - Real-time updates when order status changes")
end

# Additional test: Update some order statuses
Logger.info("")
Logger.info("=== Testing Order Status Updates ===")

# Get recent pending orders
recent_orders =
  from(o in Vendors.Order,
    where: o.status == "pending",
    order_by: [desc: o.inserted_at],
    limit: 3,
    preload: [:vendor]
  )
  |> Repo.all()

Enum.each(recent_orders, fn order ->
  Logger.info("Updating order #{order.order_number} to 'preparing'...")

  case Vendors.update_order_status(order, %{status: "preparing"}) do
    {:ok, updated_order} ->
      Logger.info("  ✅ Updated successfully")
      Logger.info("     Vendor: #{order.vendor.name}")
      Logger.info("     Check if status updated in real-time on dashboards")

    {:error, changeset} ->
      Logger.error("  ❌ Failed to update: #{inspect(changeset.errors)}")
  end

  Process.sleep(1000)
end)

Logger.info("")
Logger.info("=== All Tests Complete ===")
Logger.info("Monitor the following:")
Logger.info("  1. Vendor dashboards should show new orders immediately")
Logger.info("  2. Customer order tracking should update without refresh")
Logger.info("  3. Browser console should show WebSocket activity")
Logger.info("  4. No JavaScript errors should appear")
