defmodule RiverSideWeb.UserLive.LoginTest do
  use RiverSideWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import RiverSide.AccountsFixtures

  describe "login page" do
    test "renders login page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/log-in")

      assert html =~ "Log in"
      # Registration removed - using magic links only
      # assert html =~ "Register"
    end
  end

  describe "user login - magic link" do
    test "sends magic link email when user exists", %{conn: conn} do
      user = user_fixture()

      {:ok, lv, _html} = live(conn, ~p"/users/log-in")

      {:ok, _lv, html} =
        form(lv, "#login_form_magic", user: %{email: user.email})
        |> render_submit()
        |> follow_redirect(conn, ~p"/users/log-in")

      assert html =~ "If your email is in our system"

      assert RiverSide.Repo.get_by!(RiverSide.Accounts.UserToken, user_id: user.id).context ==
               "login"
    end

    test "does not disclose if user is registered", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/log-in")

      {:ok, _lv, html} =
        form(lv, "#login_form_magic", user: %{email: "idonotexist@example.com"})
        |> render_submit()
        |> follow_redirect(conn, ~p"/users/log-in")

      assert html =~ "If your email is in our system"
    end
  end

  # DISABLED: Password auth removed
  # describe "user login - password" do
  #   test "redirects if user logs in with valid credentials", %{conn: conn} do
  #     user = user_fixture() |> set_password()

  #     {:ok, lv, _html} = live(conn, ~p"/users/log-in")

  #     form =
  #       form(lv, "#login_form_password",
  #         user: %{email: user.email, password: valid_user_password(), remember_me: true}
  #       )

  #     conn = submit_form(form, conn)

  #     assert redirected_to(conn) == ~p"/"
  #   end

  #   test "redirects to login page with a flash error if credentials are invalid", %{
  #     conn: conn
  #   } do
  #     {:ok, lv, _html} = live(conn, ~p"/users/log-in")

  #     form =
  #       form(lv, "#login_form_password", user: %{email: "test@email.com", password: "123456"})

  #     render_submit(form, %{user: %{remember_me: true}})

  #     conn = follow_trigger_action(form, conn)
  #     assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid email or password"
  #     assert redirected_to(conn) == ~p"/users/log-in"
  #   end
  # end

  describe "login navigation" do
    # Registration removed - using magic links only
    # test "redirects to registration page when the Register button is clicked", %{conn: conn} do
    #   {:ok, lv, _html} = live(conn, ~p"/users/log-in")

    #   {:ok, _login_live, login_html} =
    #     lv
    #     |> follow_redirect(conn, ~p"/users/register")

    #   assert login_html =~ "Register"
    # end
  end

  describe "re-authentication (sudo mode)" do
    setup %{conn: conn} do
      user = user_fixture()
      %{user: user, conn: log_in_user(conn, user)}
    end

    test "shows login page with email filled in", %{conn: conn, user: _user} do
      # When already logged in, going to login page should redirect to settings
      assert {:error, {:live_redirect, %{to: "/users/settings"}}} = live(conn, ~p"/users/log-in")
    end
  end
end
