#!/usr/bin/env elixir

# Test Fix Script for River Side Food Court
# This script fixes test suite issues after removing password authentication

defmodule TestFixer do
  @moduledoc """
  Fixes test suite issues by updating tests to match the current authentication system.

  Changes made:
  1. Updates redirect paths from "/" to "/users/settings"
  2. Changes expectations from nil scope to guest scope
  3. Comments out password-related tests
  4. Updates login tests to use magic links only
  """

  def run do
    IO.puts("🔧 Fixing River Side test suite...")

    fixes = [
      # Fix redirect paths
      {
        "test/river_side_web/user_auth_test.exs",
        [
          {~r/assert redirected_to\(conn\) == ~p"\/"/,
           "assert redirected_to(conn) == ~p\"/users/settings\""}
        ]
      },

      # Fix confirmation test redirects
      {
        "test/river_side_web/live/user_live/confirmation_test.exs",
        [
          {~r/assert redirected_to\(conn\) == ~p"\/"/,
           "assert redirected_to(conn) == ~p\"/users/settings\""}
        ]
      },

      # Fix scope expectations
      {
        "test/river_side_web/user_auth_test.exs",
        [
          {~r/assert updated_socket\.assigns\.current_scope == nil/,
           "assert updated_socket.assigns.current_scope.role == :guest"}
        ]
      },

      # Comment out password tests in accounts_test.exs
      {
        "test/river_side/accounts_test.exs",
        [
          {~r/describe "get_user_by_email_and_password\/2"/,
           "# DISABLED: Password auth removed\n  # describe \"get_user_by_email_and_password/2\""},
          {~r/describe "change_user_password\/3"/,
           "# DISABLED: Password auth removed\n  # describe \"change_user_password/3\""},
          {~r/describe "update_user_password\/2"/,
           "# DISABLED: Password auth removed\n  # describe \"update_user_password/2\""}
        ]
      },

      # Fix login test to remove password form checks
      {
        "test/river_side_web/live/user_live/login_test.exs",
        [
          {~r/test "user login - password/,
           "# DISABLED: Password auth removed\n    # test \"user login - password"}
        ]
      },

      # Fix settings test to remove password change form
      {
        "test/river_side_web/live/user_live/settings_test.exs",
        [
          {~r/assert html =~ "Save Password"/,
           "# Password form removed - using magic links only\n      # assert html =~ \"Save Password\""}
        ]
      }
    ]

    Enum.each(fixes, fn {file, replacements} ->
      fix_file(file, replacements)
    end)

    # Create a simple test to verify magic link flow
    create_magic_link_test()

    IO.puts("\n✅ Test fixes complete!")
    IO.puts("\nRun `mix test` to verify the fixes.")
  end

  defp fix_file(file_path, replacements) do
    case File.read(file_path) do
      {:ok, content} ->
        new_content =
          Enum.reduce(replacements, content, fn {pattern, replacement}, acc ->
            Regex.replace(pattern, acc, replacement)
          end)

        if content != new_content do
          File.write!(file_path, new_content)
          IO.puts("✓ Fixed #{file_path}")
        else
          IO.puts("→ No changes needed for #{file_path}")
        end

      {:error, _} ->
        IO.puts("⚠ Could not read #{file_path}")
    end
  end

  defp create_magic_link_test do
    test_content = """
    defmodule RiverSideWeb.MagicLinkTest do
      use RiverSideWeb.ConnCase

      import RiverSide.AccountsFixtures

      describe "magic link authentication" do
        test "user can log in with magic link", %{conn: conn} do
          user = user_fixture()

          # Request magic link
          conn = post(conn, ~p"/users/log-in", %{
            "user" => %{"email" => user.email}
          })

          assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "login link"
          assert redirected_to(conn) == ~p"/users/log-in"
        end
      end
    end
    """

    File.write!("test/river_side_web/magic_link_test.exs", test_content)
    IO.puts("✓ Created test/river_side_web/magic_link_test.exs")
  end
end

# Run the fixer
TestFixer.run()
