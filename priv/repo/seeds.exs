# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     RiverSide.Repo.insert!(%RiverSide.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

import Ecto.Query
alias RiverSide.Repo
alias RiverSide.Accounts
alias RiverSide.Vendors
alias RiverSide.Tables
alias RiverSide.Accounts.User
alias RiverSide.Vendors.{Vendor, MenuItem, Order, OrderItem}

# Clear existing data in correct order to respect foreign keys
IO.puts("Clearing existing data...")
Repo.delete_all(OrderItem)
Repo.delete_all(Order)
Repo.delete_all(MenuItem)
Repo.delete_all(Vendor)
Repo.delete_all(RiverSide.Tables.Table)
Repo.delete_all(User)

# Create admin user
IO.puts("\nCreating admin user...")

{:ok, admin} =
  Accounts.register_user(%{
    email: System.get_env("ADMIN_EMAIL", "rroslan@gmail.com"),
    is_admin: true,
    is_vendor: false,
    is_cashier: false
  })

IO.puts("✅ Created admin user: #{admin.email}")

# Create cashier user
IO.puts("\nCreating cashier user...")

{:ok, cashier} =
  Accounts.register_user(%{
    email: System.get_env("CASHIER_EMAIL", "rosslann.ramli@gmail.com"),
    is_admin: false,
    is_vendor: false,
    is_cashier: true
  })

IO.puts("✅ Created cashier user: #{cashier.email}")

# Create drinks vendor
IO.puts("\nCreating drinks vendor...")

{:ok, drinks_vendor_user} =
  Accounts.register_user(%{
    email: System.get_env("DRINKS_VENDOR_EMAIL", "roslanr@gmail.com"),
    is_admin: false,
    is_vendor: true,
    is_cashier: false
  })

{:ok, drinks_vendor} =
  Vendors.create_vendor(%{
    name: "Cool Drinks Corner",
    description: "Refreshing beverages, juices, and specialty drinks",
    logo_url: "/images/drinks-vendor-logo.png",
    is_active: true,
    user_id: drinks_vendor_user.id
  })

IO.puts("✅ Created drinks vendor: #{drinks_vendor.name} (#{drinks_vendor_user.email})")

# Create drinks menu items
drinks_menu = [
  %{
    name: "Teh Tarik",
    description: "Traditional pulled milk tea - hot and frothy",
    price: 3.50,
    category: "drinks",
    is_available: true
  },
  %{
    name: "Iced Milo",
    description: "Chocolate malt drink served cold with ice",
    price: 4.00,
    category: "drinks",
    is_available: true
  },
  %{
    name: "Fresh Orange Juice",
    description: "Freshly squeezed orange juice, no sugar added",
    price: 6.00,
    category: "drinks",
    is_available: true
  },
  %{
    name: "Iced Lemon Tea",
    description: "Refreshing lemon tea served cold",
    price: 4.00,
    category: "drinks",
    is_available: true
  },
  %{
    name: "Bandung",
    description: "Rose syrup with evaporated milk",
    price: 3.50,
    category: "drinks",
    is_available: true
  },
  %{
    name: "Kopi O Ais",
    description: "Traditional black coffee served with ice",
    price: 3.00,
    category: "drinks",
    is_available: true
  },
  %{
    name: "Watermelon Juice",
    description: "Fresh watermelon juice, perfect for hot days",
    price: 5.50,
    category: "drinks",
    is_available: true
  },
  %{
    name: "Iced Cappuccino",
    description: "Espresso with steamed milk foam, served cold",
    price: 6.50,
    category: "drinks",
    is_available: true
  }
]

IO.puts("  Adding drinks menu items...")

for item <- drinks_menu do
  {:ok, menu_item} =
    item
    |> Map.put(:vendor_id, drinks_vendor.id)
    |> Vendors.create_menu_item()

  IO.puts("  - Added: #{menu_item.name} (RM#{menu_item.price})")
end

# Create food vendor
IO.puts("\nCreating food vendor...")

{:ok, food_vendor_user} =
  Accounts.register_user(%{
    email: System.get_env("FOOD_VENDOR_EMAIL", "dev.rroslan@gmail.com"),
    is_admin: false,
    is_vendor: true,
    is_cashier: false
  })

{:ok, food_vendor} =
  Vendors.create_vendor(%{
    name: "Mama's Kitchen",
    description: "Authentic Malaysian home-cooked meals and local favorites",
    logo_url: "/images/food-vendor-logo.png",
    is_active: true,
    user_id: food_vendor_user.id
  })

IO.puts("✅ Created food vendor: #{food_vendor.name} (#{food_vendor_user.email})")

# Create food menu items
food_menu = [
  %{
    name: "Nasi Lemak Special",
    description: "Fragrant coconut rice with sambal, fried chicken, egg, anchovies, and peanuts",
    price: 12.50,
    category: "food",
    is_available: true
  },
  %{
    name: "Char Kuey Teow",
    description: "Wok-fried flat rice noodles with prawns, cockles, and bean sprouts",
    price: 10.00,
    category: "food",
    is_available: true
  },
  %{
    name: "Chicken Rice",
    description: "Tender poached chicken with fragrant rice and special chili sauce",
    price: 8.50,
    category: "food",
    is_available: true
  },
  %{
    name: "Mee Goreng Mamak",
    description: "Spicy fried yellow noodles with tofu, potato, and egg",
    price: 8.00,
    category: "food",
    is_available: true
  },
  %{
    name: "Nasi Goreng Kampung",
    description: "Traditional village-style fried rice with anchovies and vegetables",
    price: 9.00,
    category: "food",
    is_available: true
  },
  %{
    name: "Roti Canai",
    description: "Flaky flatbread served with dhal and curry sauce",
    price: 3.50,
    category: "food",
    is_available: true
  },
  %{
    name: "Satay Ayam (6 sticks)",
    description: "Grilled chicken skewers with peanut sauce",
    price: 12.00,
    category: "food",
    is_available: true
  },
  %{
    name: "Laksa Penang",
    description: "Tangy fish-based noodle soup with herbs and vegetables",
    price: 11.00,
    category: "food",
    is_available: true
  },
  %{
    name: "Ayam Rendang",
    description: "Slow-cooked chicken in rich coconut and spice gravy, served with rice",
    price: 13.50,
    category: "food",
    is_available: true
  },
  %{
    name: "Tom Yam Seafood",
    description: "Spicy and sour Thai soup with prawns, squid, and mushrooms",
    price: 15.00,
    category: "food",
    is_available: true
  }
]

IO.puts("  Adding food menu items...")

for item <- food_menu do
  {:ok, menu_item} =
    item
    |> Map.put(:vendor_id, food_vendor.id)
    |> Vendors.create_menu_item()

  IO.puts("  - Added: #{menu_item.name} (RM#{menu_item.price})")
end

# Initialize tables
IO.puts("\nInitializing tables...")
{:ok, count} = Tables.initialize_tables()
IO.puts("✅ Initialized #{count} tables")

# Create some sample orders for testing (optional)
IO.puts("\nCreating sample orders for testing...")

# Sample order 1 - Food order
{:ok, table1} = Tables.get_table_by_number(1)

{:ok, _occupied_table1} =
  Tables.occupy_table(table1, %{customer_name: "John Doe", customer_phone: "0123456789"})

food_items = Repo.all(from m in MenuItem, where: m.vendor_id == ^food_vendor.id, limit: 3)

order_attrs = %{
  vendor_id: food_vendor.id,
  table_number: "1",
  customer_name: "John Doe",
  status: "pending",
  notes: "Less spicy please",
  order_items:
    Enum.map(food_items, fn item ->
      %{
        menu_item_id: item.id,
        quantity: Enum.random(1..2),
        unit_price: item.price,
        notes: ""
      }
    end)
}

{:ok, order1} = Vendors.create_order(order_attrs)
IO.puts("✅ Created sample food order ##{order1.order_number}")

# Sample order 2 - Drinks order
{:ok, table2} = Tables.get_table_by_number(2)

{:ok, _occupied_table2} =
  Tables.occupy_table(table2, %{customer_name: "Jane Smith", customer_phone: "0198765432"})

drinks_items = Repo.all(from m in MenuItem, where: m.vendor_id == ^drinks_vendor.id, limit: 2)

order_attrs2 = %{
  vendor_id: drinks_vendor.id,
  table_number: "2",
  customer_name: "Jane Smith",
  status: "pending",
  order_items:
    Enum.map(drinks_items, fn item ->
      %{
        menu_item_id: item.id,
        quantity: 1,
        unit_price: item.price
      }
    end)
}

{:ok, order2} = Vendors.create_order(order_attrs2)
IO.puts("✅ Created sample drinks order ##{order2.order_number}")

IO.puts("\n" <> String.duplicate("=", 60))
IO.puts("✅ SEED DATA CREATED SUCCESSFULLY!")
IO.puts(String.duplicate("=", 60))
IO.puts("\nYou can now log in with:")
IO.puts("\n📧 Admin:")
IO.puts("   Email: #{admin.email}")
IO.puts("\n📧 Cashier:")
IO.puts("   Email: #{cashier.email}")
IO.puts("\n📧 Drinks Vendor (#{drinks_vendor.name}):")
IO.puts("   Email: #{drinks_vendor_user.email}")
IO.puts("\n📧 Food Vendor (#{food_vendor.name}):")
IO.puts("   Email: #{food_vendor_user.email}")
IO.puts("\n💡 Magic login links will be sent to these email addresses!")
IO.puts(String.duplicate("=", 60))
