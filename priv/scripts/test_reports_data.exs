# Test script to generate sample data for testing reports
# Run with: mix run priv/scripts/test_reports_data.exs

require Logger
import Ecto.Query

Logger.info("Generating sample data for reports testing...")

# Get vendors
drinks_user = RiverSide.Accounts.get_user_by_email("roslanr@gmail.com")
drinks_vendor = RiverSide.Vendors.get_vendor_by_user_id(drinks_user.id)

food_user = RiverSide.Accounts.get_user_by_email("dev.rroslan@gmail.com")
food_vendor = RiverSide.Vendors.get_vendor_by_user_id(food_user.id)

# Get menu items
drinks_items = RiverSide.Vendors.list_menu_items(drinks_vendor.id)
food_items = RiverSide.Vendors.list_menu_items(food_vendor.id)

# Generate orders for the past 30 days
today = Date.utc_today()
start_date = Date.add(today, -30)

Logger.info("Creating orders from #{start_date} to #{today}...")

# Create a pattern of orders to simulate realistic data
for day_offset <- 0..30 do
  current_date = Date.add(start_date, day_offset)

  # Skip some days randomly to make it realistic
  if :rand.uniform(10) > 2 do
    # Number of orders varies by day (more on weekends)
    day_of_week = Date.day_of_week(current_date)
    base_orders = if day_of_week in [6, 7], do: 15, else: 10
    num_orders = base_orders + :rand.uniform(10)

    Logger.info("Creating #{num_orders} orders for #{current_date}")

    for order_num <- 1..num_orders do
      # Vary the time throughout the day (10 AM to 9 PM)
      hour = 10 + :rand.uniform(11) - 1
      minute = :rand.uniform(59)
      time = Time.new!(hour, minute, 0)
      datetime = DateTime.new!(current_date, time, "Etc/UTC")

      # Randomly select vendor
      {vendor, items} = if :rand.uniform(2) == 1 do
        {drinks_vendor, drinks_items}
      else
        {food_vendor, food_items}
      end

      # Create order items (1-3 items per order)
      num_items = 1 + :rand.uniform(3) - 1
      order_items = for _ <- 1..num_items do
        item = Enum.random(items)
        %{
          menu_item_id: item.id,
          quantity: 1 + :rand.uniform(3) - 1,
          price: item.price
        }
      end

      # Create the order
      table_number = to_string(:rand.uniform(20))
      customer_name = "customer_#{day_offset}_#{order_num}"

      case RiverSide.Vendors.create_order(%{
        vendor_id: vendor.id,
        customer_phone: customer_name,
        customer_name: customer_name,
        table_number: table_number,
        order_items: order_items
      }) do
        {:ok, order} ->
          # Manually update the inserted_at to our target datetime
          RiverSide.Repo.update_all(
            from(o in RiverSide.Vendors.Order, where: o.id == ^order.id),
            set: [inserted_at: datetime, updated_at: datetime]
          )

          # Progress the order through statuses
          if :rand.uniform(10) > 1 do  # 90% chance to progress
            {:ok, order} = RiverSide.Vendors.update_order_status(order, %{status: "preparing"})

            if :rand.uniform(10) > 2 do  # 80% chance to be ready
              {:ok, order} = RiverSide.Vendors.update_order_status(order, %{status: "ready"})

              # Mark as paid (70% chance)
              if :rand.uniform(10) > 3 do
                {:ok, order} = RiverSide.Vendors.mark_order_as_paid(order)

                # Update paid_at to match the order date
                RiverSide.Repo.update_all(
                  from(o in RiverSide.Vendors.Order, where: o.id == ^order.id),
                  set: [paid_at: datetime]
                )
              end

              # Complete the order (60% of ready orders)
              if :rand.uniform(10) > 4 do
                {:ok, _order} = RiverSide.Vendors.update_order_status(order, %{status: "completed"})
              end
            end
          end

        {:error, reason} ->
          Logger.error("Failed to create order: #{inspect(reason)}")
      end
    end
  end
end

# Generate summary
Logger.info("\n" <> String.duplicate("=", 50))
Logger.info("SAMPLE DATA GENERATION COMPLETE!")
Logger.info(String.duplicate("=", 50))

# Get some stats
total_orders = RiverSide.Repo.one(
  from o in RiverSide.Vendors.Order,
    select: count(o.id)
)

date_range_orders = RiverSide.Repo.one(
  from o in RiverSide.Vendors.Order,
    where: o.inserted_at >= ^DateTime.new!(start_date, ~T[00:00:00], "Etc/UTC"),
    select: count(o.id)
)

Logger.info("Total orders in database: #{total_orders}")
Logger.info("Orders created in last 30 days: #{date_range_orders}")

by_status = RiverSide.Repo.all(
  from o in RiverSide.Vendors.Order,
    where: o.inserted_at >= ^DateTime.new!(start_date, ~T[00:00:00], "Etc/UTC"),
    group_by: o.status,
    select: {o.status, count(o.id)}
)

Logger.info("\nOrder Status Distribution:")
for {status, count} <- by_status do
  Logger.info("  #{status}: #{count}")
end

by_vendor = RiverSide.Repo.all(
  from o in RiverSide.Vendors.Order,
    join: v in RiverSide.Vendors.Vendor,
    on: o.vendor_id == v.id,
    where: o.inserted_at >= ^DateTime.new!(start_date, ~T[00:00:00], "Etc/UTC"),
    group_by: v.name,
    select: {v.name, count(o.id)}
)

Logger.info("\nOrders by Vendor:")
for {vendor_name, count} <- by_vendor do
  Logger.info("  #{vendor_name}: #{count}")
end

Logger.info("\n✨ You can now view comprehensive reports in the admin dashboard!")
Logger.info("   Navigate to Admin Dashboard > System Reports")
