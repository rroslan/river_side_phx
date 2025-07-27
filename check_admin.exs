# Script to check admin users in the database
# Run with: mix run check_admin.exs

alias RiverSide.Repo
alias RiverSide.Accounts
alias RiverSide.Accounts.User

IO.puts("\n=== Checking Admin Users ===\n")

# Get all users
all_users = Repo.all(User)
IO.puts("Total users in database: #{length(all_users)}")

# Check for admin users
admin_users = Enum.filter(all_users, & &1.is_admin)
IO.puts("Admin users found: #{length(admin_users)}")

if length(admin_users) > 0 do
  IO.puts("\nAdmin user details:")

  Enum.each(admin_users, fn user ->
    IO.puts("  - Email: #{user.email}")
    IO.puts("    ID: #{user.id}")
    IO.puts("    Is Admin: #{user.is_admin}")
    IO.puts("    Is Vendor: #{user.is_vendor}")
    IO.puts("    Is Cashier: #{user.is_cashier}")
    IO.puts("    Confirmed at: #{user.confirmed_at || "Not confirmed"}")
    IO.puts("")
  end)
else
  IO.puts("\nNo admin users found!")
  IO.puts("Creating an admin user...")

  case Accounts.register_user(%{
         email: "admin@example.com",
         is_admin: true,
         is_vendor: false,
         is_cashier: false
       }) do
    {:ok, admin} ->
      IO.puts("✅ Created admin user: #{admin.email}")
      IO.puts("   ID: #{admin.id}")
      IO.puts("   Please check your email for the magic login link!")

    {:error, changeset} ->
      IO.puts("❌ Failed to create admin user:")

      Enum.each(changeset.errors, fn {field, {msg, _}} ->
        IO.puts("   - #{field}: #{msg}")
      end)
  end
end

# Test scope creation for admin users
IO.puts("\n=== Testing Scope Creation ===")

Enum.each(admin_users, fn user ->
  scope = RiverSide.Accounts.Scope.for_user(user)
  IO.puts("Scope for #{user.email}:")
  IO.puts("  - Role: #{inspect(scope.role)}")
  IO.puts("  - Is Admin?: #{RiverSide.Accounts.Scope.admin?(scope)}")
  IO.puts("  - Permissions: #{inspect(Map.keys(scope.permissions) |> Enum.take(5))} ...")
  IO.puts("")
end)

# Check if email system is configured
IO.puts("\n=== Email Configuration ===")
mailer_config = Application.get_env(:river_side, RiverSide.Mailer)
IO.puts("Mailer adapter: #{inspect(mailer_config[:adapter])}")

if mailer_config[:adapter] == Swoosh.Adapters.Local do
  IO.puts("✅ Using local adapter - check /dev/mailbox for emails")
else
  IO.puts("ℹ️  Using #{inspect(mailer_config[:adapter])}")
end

IO.puts("\n=== Instructions ===")
IO.puts("1. To log in as admin, go to: http://localhost:4000/users/log-in")
IO.puts("2. Enter the admin email: admin@example.com")
IO.puts("3. Click 'Log in with email'")
IO.puts("4. Check /dev/mailbox for the magic link")
IO.puts("5. Click the link to log in")
IO.puts("6. You should be redirected to /admin/dashboard")
