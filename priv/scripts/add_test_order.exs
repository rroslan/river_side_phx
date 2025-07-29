# Script to add a test order to table 1 for debugging real-time updates
# Run with: mix run priv/scripts/add_test_order.exs

alias RiverSide.{Vendors, Repo}
require Logger

# Configuration
table_number = "1"
customer_phone = "5551234567"

Logger.info("=== Adding Test Order to Table #{table_number} ===")

# Get the first active vendor
vendor =
  Repo.all(Vendors.Vendor)
  |> Enum.filter(& &1.is_active)
  |> List.first()

if vendor do
  Logger.info("Using vendor: #{vendor.name} (ID: #{vendor.id})")

  # Get the first available menu item from this vendor
  menu_item =
    Vendors.list_menu_items(vendor.id)
    |> Enum.filter(& &1.is_available)
    |> List.first()

  if menu_item do
    Logger.info("Using menu item: #{menu_item.name} - RM#{menu_item.price}")

    # Create the order
    order_params = %{
      vendor_id: vendor.id,
      customer_phone: customer_phone,
      customer_name: customer_phone,
      table_number: table_number,
      order_items: [
        %{
          menu_item_id: menu_item.id,
          quantity: 2,
          price: menu_item.price
        }
      ]
    }

    Logger.info("Creating order...")

    case Vendors.create_order(order_params) do
      {:ok, order} ->
        Logger.info("✅ Order created successfully!")
        Logger.info("   Order ID: #{order.id}")
        Logger.info("   Order Number: #{order.order_number}")
        Logger.info("   Total: RM#{order.total_amount}")
        Logger.info("   Status: #{order.status}")
        Logger.info("")
        Logger.info("🔔 Check if the vendor dashboard received the notification!")
        Logger.info("   - Flash message should appear")
        Logger.info("   - Order should show in active orders list")
        Logger.info("   - Check browser console for any errors")

      {:error, changeset} ->
        Logger.error("❌ Failed to create order:")
        Logger.error(inspect(changeset.errors))
    end
  else
    Logger.error("❌ No available menu items found for vendor #{vendor.name}")
    Logger.info("Please ensure the vendor has at least one available menu item.")
  end
else
  Logger.error("❌ No active vendors found in the system")
  Logger.info("Please ensure at least one vendor is active.")
end

Logger.info("")
Logger.info("=== Script Complete ===")
