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

alias RiverSide.Repo
alias RiverSide.Accounts
alias RiverSide.Vendors
alias RiverSide.Tables
alias RiverSide.Accounts.User
alias RiverSide.Vendors.{Vendor, MenuItem}

# Clear existing data in correct order to respect foreign keys
Repo.delete_all(RiverSide.Vendors.OrderItem)
Repo.delete_all(RiverSide.Vendors.Order)
Repo.delete_all(MenuItem)
Repo.delete_all(Vendor)
Repo.delete_all(User)

# Create admin user
{:ok, admin} =
  Accounts.register_user(%{
    email: System.get_env("ADMIN_EMAIL", "admin@example.com"),
    name: "Admin User",
    is_admin: true,
    is_vendor: false,
    is_cashier: false
  })

IO.puts("Created admin user: #{admin.email}")

# Create vendor users and their vendors
vendor_data = [
  %{
    user: %{
      email: System.get_env("VENDOR_EMAIL", "vendor1@example.com"),
      name: "Mama's Kitchen Owner",
      is_admin: false,
      is_vendor: true,
      is_cashier: false
    },
    vendor: %{
      name: "Mama's Kitchen",
      description: "Authentic Malaysian home-cooked meals",
      logo_url: "/images/placeholder-logo.png",
      is_active: true
    },
    menu_items: [
      %{
        name: "Nasi Lemak Special",
        description:
          "Fragrant coconut rice with sambal, fried chicken, egg, anchovies, and peanuts",
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
        name: "Teh Tarik",
        description: "Traditional pulled milk tea",
        price: 3.50,
        category: "drinks",
        is_available: true
      },
      %{
        name: "Iced Milo",
        description: "Chocolate malt drink served cold",
        price: 4.00,
        category: "drinks",
        is_available: true
      }
    ]
  },
  %{
    user: %{
      email: "vendor2@example.com",
      name: "Western Delights Owner",
      is_admin: false,
      is_vendor: true,
      is_cashier: false
    },
    vendor: %{
      name: "Western Delights",
      description: "Burgers, pasta, and more!",
      logo_url: "/images/placeholder-logo.png",
      is_active: true
    },
    menu_items: [
      %{
        name: "Classic Beef Burger",
        description: "Juicy beef patty with lettuce, tomato, onion, and special sauce",
        price: 15.00,
        category: "food",
        is_available: true
      },
      %{
        name: "Chicken Chop",
        description: "Grilled chicken with black pepper sauce, served with fries and salad",
        price: 18.00,
        category: "food",
        is_available: true
      },
      %{
        name: "Carbonara Pasta",
        description: "Creamy pasta with bacon and mushrooms",
        price: 14.00,
        category: "food",
        is_available: true
      },
      %{
        name: "Fresh Orange Juice",
        description: "Freshly squeezed orange juice",
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
      }
    ]
  },
  %{
    user: %{
      email: "vendor3@example.com",
      name: "Japanese Express Owner",
      is_admin: false,
      is_vendor: true,
      is_cashier: false
    },
    vendor: %{
      name: "Japanese Express",
      description: "Quick and delicious Japanese meals",
      logo_url: "/images/placeholder-logo.png",
      is_active: true
    },
    menu_items: [
      %{
        name: "Chicken Teriyaki Bento",
        description: "Grilled chicken with teriyaki sauce, rice, salad, and miso soup",
        price: 16.00,
        category: "food",
        is_available: true
      },
      %{
        name: "Salmon Sashimi",
        description: "Fresh salmon slices (6 pieces)",
        price: 18.00,
        category: "food",
        is_available: true
      },
      %{
        name: "Tempura Udon",
        description: "Udon noodles in hot soup with crispy tempura",
        price: 14.00,
        category: "food",
        is_available: true
      },
      %{
        name: "Green Tea",
        description: "Traditional Japanese green tea",
        price: 3.00,
        category: "drinks",
        is_available: true
      },
      %{
        name: "Ramune",
        description: "Japanese carbonated soft drink",
        price: 5.00,
        category: "drinks",
        is_available: true
      }
    ]
  }
]

# Create vendors with menu items
for vendor_info <- vendor_data do
  # Create vendor user
  {:ok, user} = Accounts.register_user(vendor_info.user)
  IO.puts("Created vendor user: #{user.email}")

  # Create vendor
  {:ok, vendor} =
    vendor_info.vendor
    |> Map.put(:user_id, user.id)
    |> Vendors.create_vendor()

  IO.puts("Created vendor: #{vendor.name}")

  # Create menu items
  for item <- vendor_info.menu_items do
    {:ok, menu_item} =
      item
      |> Map.put(:vendor_id, vendor.id)
      |> Vendors.create_menu_item()

    IO.puts("  - Added menu item: #{menu_item.name}")
  end
end

# Create cashier users
cashier_emails = [
  System.get_env("CASHIER_EMAIL", "cashier1@example.com"),
  "cashier2@example.com",
  "cashier3@example.com"
]

for {email, index} <- Enum.with_index(cashier_emails, 1) do
  {:ok, cashier} =
    Accounts.register_user(%{
      email: email,
      name: "Cashier #{index}",
      is_admin: false,
      is_vendor: false,
      is_cashier: true
    })

  IO.puts("Created cashier user: #{cashier.email}")
end

# Initialize tables
IO.puts("\nInitializing tables...")
{:ok, count} = Tables.initialize_tables()
IO.puts("✅ Initialized #{count} tables")

IO.puts("\n✅ Seed data created successfully!")
IO.puts("\nYou can now log in with:")
IO.puts("- Admin: #{System.get_env("ADMIN_EMAIL", "admin@example.com")}")
IO.puts("- Vendor: #{System.get_env("VENDOR_EMAIL", "vendor1@example.com")}")
IO.puts("- Cashier: #{System.get_env("CASHIER_EMAIL", "cashier1@example.com")}")
IO.puts("\nCheck your email for the magic login links!")
