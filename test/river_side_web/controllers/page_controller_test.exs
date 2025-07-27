defmodule RiverSideWeb.PageControllerTest do
  use RiverSideWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "River Side Food Court"
    assert html_response(conn, 200) =~ "Table 1"
    assert html_response(conn, 200) =~ "Available"
  end
end
