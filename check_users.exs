# Script to check users and generate login links
alias RiverSide.{Repo, Accounts}

IO.puts("\n=== Checking Users in Database ===\n")

users = Repo.all(Accounts.User)

if Enum.empty?(users) do
  IO.puts("❌ No users found in database!")
  IO.puts("\nRun this command to seed the database:")
  IO.puts("  mix run priv/repo/seeds.exs")
else
  IO.puts("Found #{length(users)} users:\n")

  Enum.each(users, fn user ->
    roles = []
    roles = if user.is_admin, do: ["Admin" | roles], else: roles
    roles = if user.is_vendor, do: ["Vendor" | roles], else: roles
    roles = if user.is_cashier, do: ["Cashier" | roles], else: roles

    role_string =
      case roles do
        [] -> "No roles"
        _ -> Enum.join(roles, ", ")
      end

    IO.puts("📧 #{user.email}")
    IO.puts("   Name: #{user.name || "Not set"}")
    IO.puts("   Roles: #{role_string}")
    IO.puts("   Created: #{user.inserted_at}")

    # Generate login link
    token = Accounts.generate_user_session_token(user)
    url = "http://localhost:4000/users/log-in/#{token}"

    IO.puts("   🔗 Login link (valid 15 minutes):")
    IO.puts("   #{url}")
    IO.puts("")
  end)
end

IO.puts("\n=== Checking Email Configuration ===\n")

adapter = Application.get_env(:river_side, RiverSide.Mailer)[:adapter]
IO.puts("Email adapter: #{inspect(adapter)}")

if adapter == Swoosh.Adapters.Local do
  IO.puts("\n✅ Using local email adapter")
  IO.puts("📬 View emails at: http://localhost:4000/dev/mailbox")
else
  IO.puts("\n⚠️  Using production email adapter")
end

IO.puts("\n=== Quick Actions ===\n")
IO.puts("1. To view all sent emails (development):")
IO.puts("   http://localhost:4000/dev/mailbox")
IO.puts("")
IO.puts("2. To create new users:")
IO.puts("   mix run priv/repo/seeds.exs")
IO.puts("")
IO.puts("3. To reset the database:")
IO.puts("   mix ecto.reset")
