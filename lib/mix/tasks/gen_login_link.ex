defmodule Mix.Tasks.GenLoginLink do
  @moduledoc """
  Generates a magic login link for a user.

  ## Usage

      mix gen_login_link <email>

  ## Examples

      mix gen_login_link admin@example.com
      mix gen_login_link vendor1@example.com
      mix gen_login_link cashier1@example.com

  This will output a login URL that can be used to access the account.
  """

  use Mix.Task

  @shortdoc "Generates a magic login link for a user"

  @impl Mix.Task
  def run([email]) do
    Mix.Task.run("app.start")

    alias RiverSide.Accounts
    alias RiverSide.Repo

    case Accounts.get_user_by_email(email) do
      nil ->
        Mix.shell().error("User with email '#{email}' not found")

      user ->
        token = Accounts.generate_user_session_token(user)
        url = RiverSideWeb.Endpoint.url() <> "/users/log-in/" <> token

        Mix.shell().info("\n✅ Login link generated for: #{email}")
        Mix.shell().info("\n🔗 Login URL (valid for 15 minutes):")
        Mix.shell().info("\n#{url}\n")
        Mix.shell().info("Copy and paste this URL into your browser to log in.")

        Mix.shell().info(
          "\nAlternatively, in development mode, visit: http://localhost:4000/dev/mailbox"
        )
    end
  end

  def run(_) do
    Mix.shell().error("""
    Invalid arguments.

    Usage: mix gen_login_link <email>

    Example: mix gen_login_link vendor1@example.com
    """)
  end
end
