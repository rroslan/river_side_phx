defmodule RiverSideWeb.PageController do
  use RiverSideWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
