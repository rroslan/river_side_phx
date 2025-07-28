defmodule RiverSideWeb.MagicLinkTest do
  use RiverSideWeb.ConnCase

  import RiverSide.AccountsFixtures
  import Phoenix.LiveViewTest

  describe "magic link authentication" do
    test "user can log in with magic link", %{conn: conn} do
      user = user_fixture()

      # Request magic link through LiveView
      {:ok, lv, _html} = live(conn, ~p"/users/log-in")

      {:ok, _lv, html} =
        form(lv, "#login_form_magic", user: %{email: user.email})
        |> render_submit()
        |> follow_redirect(conn, ~p"/users/log-in")

      assert html =~ "If your email is in our system"

      # Verify token was created
      assert RiverSide.Repo.get_by!(RiverSide.Accounts.UserToken, user_id: user.id).context ==
               "login"
    end
  end
end
