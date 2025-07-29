# Script to add multiple test orders specifically to Mama's Kitchen
# Run with: mix run priv/scripts/add_orders_to_mamas_kitchen.exs

alias RiverSide.{Vendors, Repo, Accounts}
import Ecto.Query
require Logger

Logger.info("=== Adding Test Orders to Mama's Kitchen ===")

# Find Mama's Kitchen vendor
vendor = Repo.one(from v in Vendors.Vendor, where: v.id == 18)

if vendor do
  Logger.info("Found vendor: #{vendor.name} (ID: #{vendor.id})")

  # Get available menu items
  menu_items =
    Vendors.list_menu_items(vendor.id)
    |> Enum.filter(& &1.is_available)

  Logger.info("Found #{length(menu_items)} available menu items")

  if length(menu_items) > 0 do
    # Create 5 orders from different tables
    tables = ["1", "5", "10", "15", "20"]
    phones = ["5551111111", "5552222222", "5553333333", "5554444444", "5555555555"]

    Enum.zip(tables, phones)
    |> Enum.with_index()
    |> Enum.each(fn {{table, phone}, index} ->
      Logger.info("")
      Logger.info("Creating order #{index + 1} for Table #{table}")

      # Select random items (1-3 items per order)
      selected_items =
        menu_items
        |> Enum.shuffle()
        |> Enum.take(Enum.random(1..3))

      order_items =
        selected_items
        |> Enum.map(fn item ->
          quantity = Enum.random(1..3)
          Logger.info("  - #{quantity}x #{item.name} @ RM#{item.price}")
          %{
            menu_item_id: item.id,
            quantity: quantity,
            price: item.price
          }
        end)

      # Create the order
      order_params = %{
        vendor_id: vendor.id,
        customer_phone: phone,
        customer_name: phone,
        table_number: table,
        order_items: order_items
      }

      case Vendors.create_order(order_params) do
        {:ok, order} ->
          Logger.info("  ✅ Order #{order.order_number} created successfully!")
          Logger.info("     Total: RM#{order.total_amount}")
          Logger.info("     Status: #{order.status}")

        {:error, changeset} ->
          Logger.error("  ❌ Failed to create order: #{inspect(changeset.errors)}")
      end

      # Wait 2 seconds between orders to see them appear one by one
      if index < 4 do
        Logger.info("  ⏳ Waiting 2 seconds before next order...")
        Process.sleep(2000)
      end
    end)

    Logger.info("")
    Logger.info("=== All Orders Created ===")
    Logger.info("Check your Mama's Kitchen vendor dashboard!")
    Logger.info("You should see:")
    Logger.info("  - Flash notifications for each order")
    Logger.info("  - 5 new orders in the active orders list")
    Logger.info("  - Orders from tables: #{Enum.join(tables, ", ")}")

    # Update one order to test status change
    Logger.info("")
    Logger.info("=== Testing Status Update ===")
    Logger.info("Updating the first order to 'preparing' status in 3 seconds...")
    Process.sleep(3000)

    # Get the most recent order for Mama's Kitchen
    recent_order =
      Repo.one(
        from o in Vendors.Order,
        where: o.vendor_id == ^vendor.id and o.status == "pending",
        order_by: [desc: o.inserted_at],
        limit: 1,
        preload: [:vendor]
      )

    if recent_order do
      case Vendors.update_order_status(recent_order, %{status: "preparing"}) do
        {:ok, updated} ->
          Logger.info("✅ Order #{updated.order_number} updated to 'preparing'")
          Logger.info("   Check if the status badge changed in real-time!")

        {:error, _} ->
          Logger.error("❌ Failed to update order status")
      end
    end

  else
    Logger.error("❌ No available menu items found for Mama's Kitchen")
    Logger.info("Please add some menu items first!")
  end
else
  Logger.error("❌ Mama's Kitchen vendor not found!")
end

Logger.info("")
Logger.info("=== Script Complete ===")
