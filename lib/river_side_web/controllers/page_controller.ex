defmodule RiverSideWeb.PageController do
  use RiverSideWeb, :controller

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
