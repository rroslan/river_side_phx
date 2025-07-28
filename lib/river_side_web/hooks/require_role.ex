defmodule RiverSideWeb.Hooks.RequireRole do
  @moduledoc """
  LiveView hooks for role-based access control.

  This module provides on_mount callbacks that can be used in live_session
  declarations to enforce role requirements. It works with the existing
  Scope-based authorization system.

  ## Usage

      live_session :admin_only,
        on_mount: [{RiverSideWeb.Hooks.RequireRole, :admin}] do
        live "/admin/users", AdminLive.Users, :index
      end
  """

  import Phoenix.LiveView
  alias RiverSide.Accounts
  alias RiverSide.Accounts.Scope

  # Requires admin role to access the LiveView.
  # Redirects to appropriate dashboard with error message if the user
  # doesn't have admin access.
  def on_mount(:admin, _params, session, socket) do
    socket = ensure_current_scope(socket, session)

    case socket.assigns[:current_scope] do
      %Scope{role: :admin} ->
        {:cont, socket}

      %Scope{} = scope ->
        {:halt, handle_unauthorized(socket, scope, "Admin access required")}

      _ ->
        {:halt, redirect_to_login(socket)}
    end
  end

  # Requires vendor role to access the LiveView.
  # Also ensures the vendor has an associated vendor record.
  def on_mount(:vendor, _params, session, socket) do
    socket = ensure_current_scope(socket, session)

    case socket.assigns[:current_scope] do
      %Scope{role: :vendor, vendor: vendor} when not is_nil(vendor) ->
        {:cont, socket}

      %Scope{role: :vendor} ->
        {:halt,
         socket
         |> put_flash(:error, "Your vendor profile is not set up. Please contact support.")
         |> redirect(to: "/")}

      %Scope{} = scope ->
        {:halt, handle_unauthorized(socket, scope, "Vendor access required")}

      _ ->
        {:halt, redirect_to_login(socket)}
    end
  end

  # Requires cashier role to access the LiveView.
  def on_mount(:cashier, _params, session, socket) do
    socket = ensure_current_scope(socket, session)

    case socket.assigns[:current_scope] do
      %Scope{role: :cashier} ->
        {:cont, socket}

      %Scope{} = scope ->
        {:halt, handle_unauthorized(socket, scope, "Cashier access required")}

      _ ->
        {:halt, redirect_to_login(socket)}
    end
  end

  # Requires customer role to access the LiveView.
  # Also checks if the customer session is still active.
  def on_mount(:customer, params, session, socket) do
    socket = ensure_customer_scope(socket, params, session)

    case socket.assigns[:current_scope] do
      %Scope{role: :customer} = scope ->
        if Scope.active_customer?(scope) do
          {:cont, socket}
        else
          {:halt,
           socket
           |> put_flash(:info, "Your session has expired. Please check in again.")
           |> redirect(to: "/")}
        end

      %Scope{} ->
        {:halt,
         socket
         |> put_flash(:info, "Please check in first")
         |> redirect(to: "/")}

      _ ->
        {:halt,
         socket
         |> put_flash(:info, "Please check in first")
         |> redirect(to: "/")}
    end
  end

  # Requires any authenticated user (admin, vendor, or cashier).
  # Does not allow customer-only sessions.
  def on_mount(:authenticated, _params, session, socket) do
    socket = ensure_current_scope(socket, session)

    case socket.assigns[:current_scope] do
      %Scope{user: user} when not is_nil(user) ->
        {:cont, socket}

      _ ->
        {:halt, redirect_to_login(socket)}
    end
  end

  # Requires specific permission to access the LiveView.
  # Example: on_mount: [{RiverSideWeb.Hooks.RequireRole, {:permission, :manage_vendors}}]
  def on_mount({:permission, permission}, _params, session, socket) when is_atom(permission) do
    socket = ensure_current_scope(socket, session)

    case socket.assigns[:current_scope] do
      %Scope{} = scope ->
        if Scope.can?(scope, permission) do
          {:cont, socket}
        else
          {:halt,
           handle_unauthorized(socket, scope, "You don't have permission to access this page")}
        end

      _ ->
        {:halt, redirect_to_login(socket)}
    end
  end

  # Allows access based on multiple roles.
  # Example: on_mount: [{RiverSideWeb.Hooks.RequireRole, {:any, [:admin, :vendor]}}]
  def on_mount({:any, roles}, _params, session, socket) when is_list(roles) do
    socket = ensure_current_scope(socket, session)

    case socket.assigns[:current_scope] do
      %Scope{role: role} = scope ->
        if role in roles do
          # Additional check for vendor to ensure vendor record exists
          if role == :vendor and is_nil(scope.vendor) do
            {:halt,
             socket
             |> put_flash(:error, "Your vendor profile is not set up. Please contact support.")
             |> redirect(to: "/")}
          else
            {:cont, socket}
          end
        else
          roles_text = roles |> Enum.map(&to_string/1) |> Enum.join(" or ")
          {:halt, handle_unauthorized(socket, scope, "This page requires #{roles_text} access")}
        end

      _ ->
        {:halt, redirect_to_login(socket)}
    end
  end

  # Private helpers

  # Ensures current_scope is assigned to socket from session
  defp ensure_current_scope(socket, session) do
    Phoenix.Component.assign_new(socket, :current_scope, fn ->
      {user, _} =
        if user_token = session["user_token"] do
          Accounts.get_user_by_session_token(user_token)
        end || {nil, nil}

      Scope.for_user(user)
    end)
  end

  # Ensures customer scope is assigned from params or session
  defp ensure_customer_scope(socket, params, session) do
    Phoenix.Component.assign_new(socket, :current_scope, fn ->
      cond do
        # Check URL params first (for new sessions)
        params["phone"] && params["table"] ->
          Scope.for_customer(params["phone"], String.to_integer(params["table"]))

        # Check session for existing customer
        session["customer_phone"] && session["customer_table"] ->
          Scope.for_customer(session["customer_phone"], session["customer_table"])

        # Try regular user session
        user_token = session["user_token"] ->
          {user, _} = Accounts.get_user_by_session_token(user_token) || {nil, nil}
          Scope.for_user(user)

        # No scope info
        true ->
          nil
      end
    end)
  end

  defp handle_unauthorized(socket, scope, message) do
    redirect_path = get_redirect_path(scope)

    socket
    |> put_flash(:error, message)
    |> redirect(to: redirect_path)
  end

  defp redirect_to_login(socket) do
    socket
    |> put_flash(:error, "You must log in to access this page.")
    |> redirect(to: "/users/log-in")
  end

  defp get_redirect_path(%Scope{role: :admin}), do: "/admin/dashboard"
  defp get_redirect_path(%Scope{role: :vendor}), do: "/vendor/dashboard"
  defp get_redirect_path(%Scope{role: :cashier}), do: "/cashier/dashboard"
  defp get_redirect_path(%Scope{role: :customer}), do: "/customer/menu"
  defp get_redirect_path(%Scope{user: user}) when not is_nil(user), do: "/users/settings"
  defp get_redirect_path(_), do: "/"
end
