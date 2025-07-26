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

alias RiverSide.Accounts

# Get email addresses from environment variables
admin_email = System.get_env("ADMIN_EMAIL") || "rroslan@gmail.com"
vendor_email = System.get_env("VENDOR_EMAIL") || "roslanr@gmail.com"
cashier_email = System.get_env("CASHIER_EMAIL") || "rosslann.ramli@gmail.com"

IO.puts("\n=== Seeding Database ===\n")

# Create or update admin user
case Accounts.create_or_update_user_with_roles(admin_email, %{
       is_admin: true,
       is_vendor: false,
       is_cashier: false
     }) do
  {:ok, user} ->
    action = if user.inserted_at == user.updated_at, do: "Created", else: "Updated"
    IO.puts("✓ #{action} Admin user: #{user.email}")

  {:error, changeset} ->
    IO.puts("✗ Failed to process Admin user: #{inspect(changeset.errors)}")
end

# Create or update vendor user
case Accounts.create_or_update_user_with_roles(vendor_email, %{
       is_admin: false,
       is_vendor: true,
       is_cashier: false
     }) do
  {:ok, user} ->
    action = if user.inserted_at == user.updated_at, do: "Created", else: "Updated"
    IO.puts("✓ #{action} Vendor user: #{user.email}")

  {:error, changeset} ->
    IO.puts("✗ Failed to process Vendor user: #{inspect(changeset.errors)}")
end

# Create or update cashier user
case Accounts.create_or_update_user_with_roles(cashier_email, %{
       is_admin: false,
       is_vendor: false,
       is_cashier: true
     }) do
  {:ok, user} ->
    action = if user.inserted_at == user.updated_at, do: "Created", else: "Updated"
    IO.puts("✓ #{action} Cashier user: #{user.email}")

  {:error, changeset} ->
    IO.puts("✗ Failed to process Cashier user: #{inspect(changeset.errors)}")
end

IO.puts("\n=== Seed Complete ===")
IO.puts("\nConfigured users:")
IO.puts("- Admin: #{admin_email}")
IO.puts("- Vendor: #{vendor_email}")
IO.puts("- Cashier: #{cashier_email}")
IO.puts("\nUsers can log in using magic links sent to their email addresses.")
IO.puts("\nNote: Existing users' roles have been updated if they already existed.")
