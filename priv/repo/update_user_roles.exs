# Script to update existing users with role fields
# Run with: mix run priv/repo/update_user_roles.exs

alias RiverSide.Repo
alias RiverSide.Accounts.User
import Ecto.Query

IO.puts("Starting user role update...\n")

# Get all users
users = Repo.all(User)
IO.puts("Found #{length(users)} users to check\n")

# Define role mappings based on email patterns
admin_emails = [
  System.get_env("ADMIN_EMAIL", "admin@example.com"),
  "admin@example.com"
]

vendor_emails = [
  System.get_env("VENDOR1_EMAIL", "vendor1@example.com"),
  System.get_env("VENDOR2_EMAIL", "vendor2@example.com"),
  System.get_env("VENDOR3_EMAIL", "vendor3@example.com"),
  "vendor1@example.com",
  "vendor2@example.com",
  "vendor3@example.com"
]

cashier_emails = [
  System.get_env("CASHIER_EMAIL", "cashier1@example.com"),
  "cashier1@example.com",
  "cashier2@example.com",
  "cashier3@example.com"
]

# Track statistics
stats = %{
  updated: 0,
  skipped: 0,
  admin: 0,
  vendor: 0,
  cashier: 0,
  regular: 0
}

# Update each user
final_stats =
  Enum.reduce(users, stats, fn user, acc ->
    # Determine what roles this user should have
    should_be_admin = user.email in admin_emails
    should_be_vendor = user.email in vendor_emails
    should_be_cashier = user.email in cashier_emails

    # Check if update is needed
    needs_update =
      user.is_admin != should_be_admin ||
      user.is_vendor != should_be_vendor ||
      user.is_cashier != should_be_cashier ||
      is_nil(user.is_admin) ||
      is_nil(user.is_vendor) ||
      is_nil(user.is_cashier)

    if needs_update do
      # Update the user
      user
      |> Ecto.Changeset.change(%{
        is_admin: should_be_admin,
        is_vendor: should_be_vendor,
        is_cashier: should_be_cashier
      })
      |> Repo.update!()

      # Determine role type for logging
      role_type = cond do
        should_be_admin -> "admin"
        should_be_vendor -> "vendor"
        should_be_cashier -> "cashier"
        true -> "regular user"
      end

      IO.puts("✅ Updated #{user.email} as #{role_type}")

      # Update statistics
      acc
      |> Map.update!(:updated, &(&1 + 1))
      |> Map.update!(String.to_atom(role_type |> String.replace(" user", "")), &(&1 + 1))
    else
      # Skip if no update needed
      IO.puts("⏭️  Skipped #{user.email} (already correct)")
      Map.update!(acc, :skipped, &(&1 + 1))
    end
  end)

# Print summary
IO.puts("\n" <> String.duplicate("=", 50))
IO.puts("Update Summary:")
IO.puts(String.duplicate("=", 50))
IO.puts("Total users processed: #{length(users)}")
IO.puts("Users updated: #{final_stats.updated}")
IO.puts("Users skipped: #{final_stats.skipped}")
IO.puts("\nRole breakdown of updated users:")
IO.puts("  Admins: #{final_stats.admin}")
IO.puts("  Vendors: #{final_stats.vendor}")
IO.puts("  Cashiers: #{final_stats.cashier}")
IO.puts("  Regular users: #{final_stats.regular}")
IO.puts("\n✅ User role update completed!")

# Verify the update by showing current role distribution
IO.puts("\nCurrent role distribution in database:")

admin_count = Repo.one(from u in User, where: u.is_admin == true, select: count(u.id))
vendor_count = Repo.one(from u in User, where: u.is_vendor == true, select: count(u.id))
cashier_count = Repo.one(from u in User, where: u.is_cashier == true, select: count(u.id))
regular_count = Repo.one(
  from u in User,
  where: u.is_admin == false and u.is_vendor == false and u.is_cashier == false,
  select: count(u.id)
)

IO.puts("  Total admins: #{admin_count}")
IO.puts("  Total vendors: #{vendor_count}")
IO.puts("  Total cashiers: #{cashier_count}")
IO.puts("  Total regular users: #{regular_count}")
