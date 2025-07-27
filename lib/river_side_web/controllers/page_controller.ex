defmodule RiverSideWeb.PageController do
  @moduledoc """
  Controller for handling the main landing page and user routing.

  This controller manages the home page display and intelligently
  redirects authenticated users to their role-specific dashboards.
  It serves as the entry point for the River Side Food Court web interface.

  ## Routing Logic

  The home action implements role-based routing:

  * **Unauthenticated users** → See the public home page
  * **Admin users** → Redirected to admin dashboard
  * **Vendor users** → Redirected to vendor dashboard
  * **Cashier users** → Redirected to cashier dashboard
  * **Regular users** → See the standard home page

  ## Security

  The controller checks for `current_scope` in the connection assigns,
  which is set by the authentication plug pipeline. This ensures
  users are properly authenticated before role-based routing occurs.
  """
  use RiverSideWeb, :controller

  @doc """
  Renders the home page or redirects to role-specific dashboard.

  Checks if the user is authenticated via `current_scope` and routes
  them to the appropriate dashboard based on their role. Unauthenticated
  users see the public home page with login options.

  ## Parameters

  * `conn` - The connection struct
  * `_params` - Unused request parameters

  ## Returns

  * Renders `:home` template for unauthenticated or regular users
  * Redirects to role-specific dashboard for special users

  ## Examples

  Authenticated admin user:
      GET / → 302 Redirect to /admin/dashboard

  Unauthenticated user:
      GET / → 200 OK (renders home page)
  """
  def home(conn, _params) do
    if conn.assigns[:current_scope] do
      user = conn.assigns.current_scope.user

      cond do
        user.is_admin ->
          redirect(conn, to: ~p"/admin/dashboard")

        user.is_vendor ->
          redirect(conn, to: ~p"/vendor/dashboard")

        user.is_cashier ->
          redirect(conn, to: ~p"/cashier/dashboard")

        true ->
          render(conn, :home)
      end
    else
      render(conn, :home)
    end
  end
end
