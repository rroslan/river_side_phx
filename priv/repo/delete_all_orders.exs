# Script to delete all orders and related data
# Run with: mix run priv/repo/delete_all_orders.exs

alias RiverSide.Repo
alias RiverSide.Vendors.{Order, OrderItem}

IO.puts("Starting order deletion process...\n")

# First, delete all order items
{order_items_count, _} = Repo.delete_all(OrderItem)
IO.puts("✓ Deleted #{order_items_count} order items")

# Then delete all orders
{orders_count, _} = Repo.delete_all(Order)
IO.puts("✓ Deleted #{orders_count} orders")

# Also reset any occupied tables
alias RiverSide.Tables.Table
Repo.update_all(Table, set: [occupied_at: nil])
IO.puts("✓ Reset all tables to unoccupied")

IO.puts("\n✅ All orders have been deleted successfully!")
IO.puts("You can now start fresh with your testing.")
