# Test script to create multiple orders from different vendors to test vendor grouping
# Run with: mix run priv/scripts/test_vendor_grouping.exs

require Logger

# Get vendors
drinks_user = RiverSide.Accounts.get_user_by_email("roslanr@gmail.com")
drinks_vendor = RiverSide.Vendors.get_vendor_by_user_id(drinks_user.id)
Logger.info("Found drinks vendor: #{drinks_vendor.name}")

food_user = RiverSide.Accounts.get_user_by_email("dev.rroslan@gmail.com")
food_vendor = RiverSide.Vendors.get_vendor_by_user_id(food_user.id)
Logger.info("Found food vendor: #{food_vendor.name}")

# Get menu items for each vendor
drinks_items = RiverSide.Vendors.list_menu_items(drinks_vendor.id)
food_items = RiverSide.Vendors.list_menu_items(food_vendor.id)

Logger.info("Creating test orders for vendor grouping demonstration...")

# Create orders for different tables and vendors
test_scenarios = [
  # Table 1 - Mixed vendors
  %{
    vendor: drinks_vendor,
    item: Enum.at(drinks_items, 0),
    table: "1",
    customer: "test_customer_1"
  },
  %{
    vendor: food_vendor,
    item: Enum.at(food_items, 0),
    table: "1",
    customer: "test_customer_1"
  },

  # Table 2 - Only drinks
  %{
    vendor: drinks_vendor,
    item: Enum.at(drinks_items, 1),
    table: "2",
    customer: "test_customer_2"
  },
  %{
    vendor: drinks_vendor,
    item: Enum.at(drinks_items, 2),
    table: "2",
    customer: "test_customer_2"
  },

  # Table 3 - Only food
  %{
    vendor: food_vendor,
    item: Enum.at(food_items, 1),
    table: "3",
    customer: "test_customer_3"
  },

  # Table 4 - Mixed vendors
  %{
    vendor: drinks_vendor,
    item: Enum.at(drinks_items, 3),
    table: "4",
    customer: "test_customer_4"
  },
  %{
    vendor: food_vendor,
    item: Enum.at(food_items, 2),
    table: "4",
    customer: "test_customer_4"
  },
  %{
    vendor: food_vendor,
    item: Enum.at(food_items, 3),
    table: "4",
    customer: "test_customer_4"
  }
]

# Create orders
_created_orders = []

for scenario <- test_scenarios do
  order_attrs = %{
    vendor_id: scenario.vendor.id,
    customer_phone: scenario.customer,
    customer_name: scenario.customer,
    table_number: scenario.table,
    order_items: [
      %{
        menu_item_id: scenario.item.id,
        quantity: Enum.random(1..3),
        price: scenario.item.price
      }
    ]
  }

  case RiverSide.Vendors.create_order(order_attrs) do
    {:ok, order} ->
      Logger.info("✅ Created order ##{order.order_number} - #{scenario.vendor.name} for Table #{scenario.table}")

      # Randomly set some orders to different statuses using valid transitions
      # pending -> preparing -> ready
      if Enum.random([true, false, false]) do  # 1/3 chance to update status
        # First transition to preparing
        {:ok, preparing_order} = RiverSide.Vendors.update_order_status(order, %{status: "preparing"})
        Logger.info("   Updated to status: preparing")

        # Maybe transition to ready
        if Enum.random([true, false]) do
          {:ok, ready_order} = RiverSide.Vendors.update_order_status(preparing_order, %{status: "ready"})
          Logger.info("   Updated to status: ready")

          # If ready, randomly mark some as paid
          if Enum.random([true, false]) do
            {:ok, _} = RiverSide.Vendors.mark_order_as_paid(ready_order)
            Logger.info("   Marked as paid")
          end
        end
      end

      Process.sleep(100) # Small delay between orders

    {:error, reason} ->
      Logger.error("❌ Failed to create order: #{inspect(reason)}")
  end
end

# Summary
Logger.info("\n" <> String.duplicate("=", 50))
Logger.info("TEST DATA CREATED SUCCESSFULLY!")
Logger.info(String.duplicate("=", 50))
Logger.info("\nOrder Summary:")

# Group by vendor
vendor_orders = RiverSide.Vendors.list_active_orders(nil)
|> Enum.group_by(& &1.vendor.name)

for {vendor_name, orders} <- vendor_orders do
  Logger.info("\n#{vendor_name}:")
  Logger.info("  Total orders: #{length(orders)}")

  status_counts = Enum.frequencies_by(orders, & &1.status)
  for {status, count} <- status_counts do
    Logger.info("  - #{status}: #{count}")
  end

  paid_count = Enum.count(orders, & &1.paid)
  if paid_count > 0 do
    Logger.info("  - paid: #{paid_count}")
  end
end

# Group by table
table_orders = RiverSide.Vendors.list_active_orders(nil)
|> Enum.group_by(& &1.table_number)

Logger.info("\n\nTable Summary:")
for {table_number, orders} <- Enum.sort_by(table_orders, fn {t, _} -> String.to_integer(t) end) do
  vendors = orders |> Enum.map(& &1.vendor.name) |> Enum.uniq() |> Enum.join(", ")
  total = Enum.reduce(orders, Decimal.new("0"), fn o, acc -> Decimal.add(acc, o.total_amount) end)
  Logger.info("  Table #{table_number}: #{length(orders)} orders from #{vendors} - Total: RM#{total}")
end

Logger.info("\n✨ You can now test the vendor grouping feature in the cashier dashboard!")
Logger.info("   Use the 'By Table' / 'By Vendor' toggle to switch views")
