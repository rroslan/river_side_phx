defmodule RiverSideWeb.Hooks.ExampleComparison do
  @moduledoc """
  This module shows the comparison between the original hook implementation
  and how it should be properly implemented in the River Side system.
  """

  # ============================================================================
  # ORIGINAL IMPLEMENTATION (Won't work with current system)
  # ============================================================================
  # This implementation has several issues:
  # 1. It assumes current_user exists directly in assigns
  # 2. It assumes current_user has is_admin field accessible
  # 3. It doesn't follow the existing Scope-based pattern
  # 4. The redirect path might not exist

  defmodule OriginalVersion do
    import Phoenix.LiveView

    def on_mount(:admin, _params, _session, socket) do
      if socket.assigns.current_user.is_admin do
        {:cont, socket}
      else
        {:halt, socket |> Phoenix.LiveView.redirect(to: "/unauthorized")}
      end
    end
  end

  # ============================================================================
  # CORRECTED VERSION 1: Direct User Check (Simple but limited)
  # ============================================================================
  # This version works with the existing system but doesn't leverage
  # the Scope pattern fully

  defmodule CorrectedVersionSimple do
    import Phoenix.LiveView

    def on_mount(:admin, _params, _session, socket) do
      case socket.assigns[:current_scope] do
        %{user: %{is_admin: true}} ->
          {:cont, socket}

        %{user: _user} ->
          {:halt,
           socket
           |> put_flash(:error, "Admin access required")
           |> redirect(to: "/")}

        _ ->
          {:halt,
           socket
           |> put_flash(:error, "You must log in to access this page")
           |> redirect(to: "/users/log-in")}
      end
    end
  end

  # ============================================================================
  # CORRECTED VERSION 2: Using Scope Pattern (Recommended)
  # ============================================================================
  # This version properly uses the Scope-based authorization system

  defmodule CorrectedVersionScope do
    import Phoenix.LiveView
    alias RiverSide.Accounts.Scope

    def on_mount(:admin, _params, _session, socket) do
      case socket.assigns[:current_scope] do
        %Scope{role: :admin} ->
          {:cont, socket}

        %Scope{} = scope ->
          # Redirect to appropriate dashboard based on user's actual role
          redirect_path = get_redirect_path(scope)

          {:halt,
           socket
           |> put_flash(:error, "Admin access required")
           |> redirect(to: redirect_path)}

        _ ->
          {:halt,
           socket
           |> put_flash(:error, "You must log in to access this page")
           |> redirect(to: "/users/log-in")}
      end
    end

    defp get_redirect_path(%Scope{role: :vendor}), do: "/vendor/dashboard"
    defp get_redirect_path(%Scope{role: :cashier}), do: "/cashier/dashboard"
    defp get_redirect_path(%Scope{user: %{}}), do: "/users/settings"
    defp get_redirect_path(_), do: "/"
  end

  # ============================================================================
  # USAGE EXAMPLES
  # ============================================================================

  @doc """
  Example of how to use these hooks in router.ex
  """
  def router_example do
    """
    # In router.ex

    # Using the original (broken) version
    live_session :admin_original,
      on_mount: [{RiverSideWeb.Hooks.RequireRole, :admin}] do
      live "/admin/test1", AdminLive.Test, :index
    end

    # Using the corrected simple version
    live_session :admin_simple,
      on_mount: [
        {RiverSideWeb.UserAuth, :mount_current_scope},
        {RiverSideWeb.Hooks.ExampleComparison.CorrectedVersionSimple, :admin}
      ] do
      live "/admin/test2", AdminLive.Test, :index
    end

    # Using the recommended Scope version
    live_session :admin_scope,
      on_mount: [
        {RiverSideWeb.UserAuth, :mount_current_scope},
        {RiverSideWeb.Hooks.ExampleComparison.CorrectedVersionScope, :admin}
      ] do
      live "/admin/test3", AdminLive.Test, :index
    end

    # Or just use the existing UserAuth hook (simplest)
    live_session :admin_existing,
      on_mount: [{RiverSideWeb.UserAuth, :require_admin_scope}] do
      live "/admin/test4", AdminLive.Test, :index
    end
    """
  end

  # ============================================================================
  # KEY DIFFERENCES EXPLAINED
  # ============================================================================

  @doc """
  Explains the key differences between implementations
  """
  def differences do
    %{
      original_issues: [
        "Assumes socket.assigns.current_user exists (it's actually in current_scope)",
        "Direct access to is_admin field doesn't follow the Scope pattern",
        "No handling for unauthenticated users",
        "Hardcoded redirect to /unauthorized which might not exist",
        "No error messages for users"
      ],
      corrections_made: [
        "Uses socket.assigns.current_scope instead of current_user",
        "Checks the Scope.role instead of user.is_admin directly",
        "Handles unauthenticated users with redirect to login",
        "Redirects to appropriate dashboards based on user's actual role",
        "Provides informative error messages",
        "Follows the existing authorization patterns in the codebase"
      ],
      why_scope_pattern: [
        "Centralizes role determination logic",
        "Includes permissions and additional context (like vendor info)",
        "Consistent with existing codebase patterns",
        "Easier to extend with new roles or permissions",
        "Better separation of concerns"
      ]
    }
  end

  # ============================================================================
  # TESTING EXAMPLE
  # ============================================================================

  @doc """
  Example test for the hook
  """
  def test_example do
    """
    defmodule RiverSideWeb.Hooks.RequireRoleTest do
      use RiverSideWeb.ConnCase
      import Phoenix.LiveViewTest

      alias RiverSide.AccountsFixtures

      describe "admin hook" do
        test "allows admin users", %{conn: conn} do
          admin = AccountsFixtures.user_fixture(%{is_admin: true})
          conn = log_in_user(conn, admin)

          # Assuming you have a test LiveView
          {:ok, _view, html} = live(conn, "/admin/test")
          assert html =~ "Admin Content"
        end

        test "redirects vendor users", %{conn: conn} do
          vendor = AccountsFixtures.user_fixture(%{is_vendor: true})
          conn = log_in_user(conn, vendor)

          {:error, {:redirect, %{to: "/vendor/dashboard", flash: flash}}} =
            live(conn, "/admin/test")

          assert flash["error"] =~ "Admin access required"
        end

        test "redirects unauthenticated users to login", %{conn: conn} do
          {:error, {:redirect, %{to: "/users/log-in", flash: flash}}} =
            live(conn, "/admin/test")

          assert flash["error"] =~ "You must log in"
        end
      end
    end
    """
  end
end
