defmodule RiverSideWeb.UserAuth do
  use RiverSideWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller

  alias RiverSide.Accounts
  alias RiverSide.Accounts.{Scope, User}

  # Make the remember me cookie valid for 14 days. This should match
  # the session validity setting in UserToken.
  @max_cookie_age_in_days 14
  @remember_me_cookie "_river_side_web_user_remember_me"
  @remember_me_options [
    sign: true,
    max_age: @max_cookie_age_in_days * 24 * 60 * 60,
    same_site: "Lax"
  ]

  # How old the session token should be before a new one is issued. When a request is made
  # with a session token older than this value, then a new session token will be created
  # and the session and remember-me cookies (if set) will be updated with the new token.
  # Lowering this value will result in more tokens being created by active users. Increasing
  # it will result in less time before a session token expires for a user to get issued a new
  # token. This can be set to a value greater than `@max_cookie_age_in_days` to disable
  # the reissuing of tokens completely.
  @session_reissue_age_in_days 7

  @doc """
  Logs the user in.

  Redirects to the session's `:user_return_to` path
  or falls back to the `signed_in_path/1`.
  """
  def log_in_user(conn, user, params \\ %{}) do
    user_return_to = get_session(conn, :user_return_to)

    # Create scope for the user to determine redirect path
    scope = Scope.for_user(user)

    conn
    |> create_or_extend_session(user, params)
    |> assign(:current_scope, scope)
    |> redirect(to: user_return_to || signed_in_path_for_scope(scope))
  end

  @doc """
  Creates a customer session.

  This is used when customers check in with their phone and table number.
  """
  def create_customer_session(conn, phone, table_number) do
    conn
    |> put_session(:customer_phone, phone)
    |> put_session(:customer_table, table_number)
    |> put_session(:customer_session_id, generate_session_id())
  end

  defp generate_session_id do
    :crypto.strong_rand_bytes(16) |> Base.encode64()
  end

  @doc """
  Logs the user out.

  It clears all session data for safety. See renew_session.
  """
  def log_out_user(conn) do
    user_token = get_session(conn, :user_token)
    user_token && Accounts.delete_user_session_token(user_token)

    if live_socket_id = get_session(conn, :live_socket_id) do
      RiverSideWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn
    |> renew_session(nil)
    |> delete_resp_cookie(@remember_me_cookie)
    |> redirect(to: ~p"/")
  end

  @doc """
  Authenticates the user by looking into the session and remember me token.

  Will reissue the session token if it is older than the configured age.
  """
  def fetch_current_scope_for_user(conn, _opts) do
    with {token, conn} <- ensure_user_token(conn),
         {user, token_inserted_at} <- Accounts.get_user_by_session_token(token) do
      conn
      |> assign(:current_scope, Scope.for_user(user))
      |> maybe_reissue_user_session_token(user, token_inserted_at)
    else
      nil -> assign(conn, :current_scope, nil)
    end
  end

  defp ensure_user_token(conn) do
    if token = get_session(conn, :user_token) do
      {token, conn}
    else
      conn = fetch_cookies(conn, signed: [@remember_me_cookie])

      if token = conn.cookies[@remember_me_cookie] do
        {token, conn |> put_token_in_session(token) |> put_session(:user_remember_me, true)}
      else
        nil
      end
    end
  end

  # Reissue the session token if it is older than the configured reissue age.
  defp maybe_reissue_user_session_token(conn, user, token_inserted_at) do
    token_age = DateTime.diff(DateTime.utc_now(:second), token_inserted_at, :day)

    if token_age >= @session_reissue_age_in_days do
      create_or_extend_session(conn, user, %{})
    else
      conn
    end
  end

  # This function is the one responsible for creating session tokens
  # and storing them safely in the session and cookies. It may be called
  # either when logging in, during sudo mode, or to renew a session which
  # will soon expire.
  #
  # When the session is created, rather than extended, the renew_session
  # function will clear the session to avoid fixation attacks. See the
  # renew_session function to customize this behaviour.
  defp create_or_extend_session(conn, user, params) do
    token = Accounts.generate_user_session_token(user)
    remember_me = get_session(conn, :user_remember_me)

    conn
    |> renew_session(user)
    |> put_token_in_session(token)
    |> maybe_write_remember_me_cookie(token, params, remember_me)
  end

  # Do not renew session if the user is already logged in
  # to prevent CSRF errors or data being lost in tabs that are still open
  defp renew_session(conn, user) when is_struct(user, User) do
    case conn.assigns[:current_scope] do
      %Scope{user: %User{id: user_id}} when user_id == user.id ->
        conn

      _ ->
        renew_session_impl(conn, user)
    end
  end

  defp renew_session(conn, nil) do
    renew_session_impl(conn, nil)
  end

  # This function renews the session ID and erases the whole
  # session to avoid fixation attacks. If there is any data
  # in the session you may want to preserve after log in/log out,
  # you must explicitly fetch the session data before clearing
  # and then immediately set it after clearing, for example:
  #
  #     defp renew_session_impl(conn, _user) do
  #       delete_csrf_token()
  #       preferred_locale = get_session(conn, :preferred_locale)
  #
  #       conn
  #       |> configure_session(renew: true)
  #       |> clear_session()
  #       |> put_session(:preferred_locale, preferred_locale)
  #     end
  #
  defp renew_session_impl(conn, _user) do
    delete_csrf_token()

    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  defp maybe_write_remember_me_cookie(conn, token, %{"remember_me" => "true"}, _),
    do: write_remember_me_cookie(conn, token)

  defp maybe_write_remember_me_cookie(conn, token, _params, true),
    do: write_remember_me_cookie(conn, token)

  defp maybe_write_remember_me_cookie(conn, _token, _params, _), do: conn

  defp write_remember_me_cookie(conn, token) do
    conn
    |> put_session(:user_remember_me, true)
    |> put_resp_cookie(@remember_me_cookie, token, @remember_me_options)
  end

  defp put_token_in_session(conn, token) do
    conn
    |> put_session(:user_token, token)
    |> put_session(:live_socket_id, user_session_topic(token))
  end

  @doc """
  Disconnects existing sockets for the given tokens.
  """
  def disconnect_sessions(tokens) do
    Enum.each(tokens, fn %{token: token} ->
      RiverSideWeb.Endpoint.broadcast(user_session_topic(token), "disconnect", %{})
    end)
  end

  defp user_session_topic(token), do: "users_sessions:#{Base.url_encode64(token)}"

  @doc """
  Handles mounting and authenticating the current_scope in LiveViews.

  ## `on_mount` arguments

    * `:mount_current_scope` - Assigns current_scope
      to socket assigns based on user_token, or nil if
      there's no user_token or no matching user.

    * `:require_authenticated` - Authenticates the user from the session,
      and assigns the current_scope to socket assigns based
      on user_token.
      Redirects to login page if there's no logged user.

  ## Examples

  Use the `on_mount` lifecycle macro in LiveViews to mount or authenticate
  the `current_scope`:

      defmodule RiverSideWeb.PageLive do
        use RiverSideWeb, :live_view

        on_mount {RiverSideWeb.UserAuth, :mount_current_scope}
        ...
      end

  Or use the `live_session` of your router to invoke the on_mount callback:

      live_session :authenticated, on_mount: [{RiverSideWeb.UserAuth, :require_authenticated}] do
        live "/profile", ProfileLive, :index
      end
  """
  def on_mount(:mount_current_scope, _params, session, socket) do
    {:cont, mount_current_scope(socket, session)}
  end

  def on_mount(:mount_guest_scope, _params, _session, socket) do
    {:cont, Phoenix.Component.assign(socket, :current_scope, nil)}
  end

  def on_mount(:mount_customer_scope, params, session, socket) do
    scope = get_customer_scope(params, session)

    if scope && Scope.active_customer?(scope) do
      {:cont, Phoenix.Component.assign(socket, :current_scope, scope)}
    else
      # Allow checkin page to be accessed without scope
      if params["_action"] == "new" do
        {:cont, Phoenix.Component.assign(socket, :current_scope, nil)}
      else
        {:halt, redirect_to_checkin(socket)}
      end
    end
  end

  def on_mount(:require_authenticated, _params, session, socket) do
    socket = mount_current_scope(socket, session)

    if Scope.authenticated?(socket.assigns.current_scope) do
      {:cont, socket}
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(:error, "You must log in to access this page.")
        |> Phoenix.LiveView.redirect(to: ~p"/users/log-in")

      {:halt, socket}
    end
  end

  def on_mount(:require_admin_scope, _params, session, socket) do
    socket = mount_current_scope(socket, session)

    if Scope.admin?(socket.assigns.current_scope) do
      {:cont, socket}
    else
      {:halt, handle_unauthorized(socket, "Admin access required")}
    end
  end

  def on_mount(:require_vendor_scope, _params, session, socket) do
    socket = mount_current_scope(socket, session)
    scope = socket.assigns.current_scope

    if Scope.vendor?(scope) && scope.vendor do
      {:cont, socket}
    else
      {:halt, handle_unauthorized(socket, "Vendor access required")}
    end
  end

  def on_mount(:require_cashier_scope, _params, session, socket) do
    socket = mount_current_scope(socket, session)

    if Scope.cashier?(socket.assigns.current_scope) do
      {:cont, socket}
    else
      {:halt, handle_unauthorized(socket, "Cashier access required")}
    end
  end

  def on_mount(:require_sudo_mode, _params, session, socket) do
    socket = mount_current_scope(socket, session)

    if Accounts.sudo_mode?(socket.assigns.current_scope.user, -10) do
      {:cont, socket}
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(:error, "You must re-authenticate to access this page.")
        |> Phoenix.LiveView.redirect(to: ~p"/users/log-in")

      {:halt, socket}
    end
  end

  defp mount_current_scope(socket, session) do
    Phoenix.Component.assign_new(socket, :current_scope, fn ->
      {user, _} =
        if user_token = session["user_token"] do
          Accounts.get_user_by_session_token(user_token)
        end || {nil, nil}

      Scope.for_user(user)
    end)
  end

  # Customer scope management
  defp get_customer_scope(params, session) do
    cond do
      # Check URL params first (for new sessions)
      params["phone"] && params["table"] ->
        Scope.for_customer(params["phone"], String.to_integer(params["table"]))

      # Check session for existing customer
      session["customer_phone"] && session["customer_table"] ->
        Scope.for_customer(session["customer_phone"], session["customer_table"])

      # No customer info
      true ->
        nil
    end
  end

  defp redirect_to_checkin(socket) do
    socket
    |> Phoenix.LiveView.put_flash(:info, "Please check in first")
    |> Phoenix.LiveView.redirect(to: ~p"/")
  end

  defp handle_unauthorized(socket, message) do
    redirect_path =
      case socket.assigns[:current_scope] do
        %{role: :vendor} -> ~p"/vendor/dashboard"
        %{role: :cashier} -> ~p"/cashier/dashboard"
        %{role: :admin} -> ~p"/admin/dashboard"
        %{user: nil} -> ~p"/users/log-in"
        _ -> ~p"/"
      end

    socket
    |> Phoenix.LiveView.put_flash(:error, message)
    |> Phoenix.LiveView.redirect(to: redirect_path)
  end

  @doc "Returns the path to redirect to after log in."
  def signed_in_path(conn) do
    case conn.assigns[:current_scope] do
      %Scope{role: :admin} -> ~p"/admin/dashboard"
      %Scope{role: :vendor} -> ~p"/vendor/dashboard"
      %Scope{role: :cashier} -> ~p"/cashier/dashboard"
      %Scope{user: %User{}} -> ~p"/users/settings"
      _ -> ~p"/"
    end
  end

  # Helper function to get signed in path directly from scope
  defp signed_in_path_for_scope(%Scope{role: :admin}), do: ~p"/admin/dashboard"
  defp signed_in_path_for_scope(%Scope{role: :vendor}), do: ~p"/vendor/dashboard"
  defp signed_in_path_for_scope(%Scope{role: :cashier}), do: ~p"/cashier/dashboard"
  defp signed_in_path_for_scope(%Scope{user: %User{}}), do: ~p"/users/settings"
  defp signed_in_path_for_scope(_), do: ~p"/"

  @doc """
  Plug for routes that require the user to be authenticated.
  """
  def require_authenticated_user(conn, _opts) do
    if Scope.authenticated?(conn.assigns[:current_scope]) do
      conn
    else
      conn
      |> put_flash(:error, "You must log in to access this page.")
      |> maybe_store_return_to()
      |> redirect(to: ~p"/users/log-in")
      |> halt()
    end
  end

  @doc """
  Plug for routes that require admin access.
  """
  def require_admin_user(conn, _opts) do
    if Scope.admin?(conn.assigns[:current_scope]) do
      conn
    else
      conn
      |> put_flash(:error, "Admin access required.")
      |> redirect(to: signed_in_path(conn))
      |> halt()
    end
  end

  @doc """
  Plug for routes that require vendor access.
  """
  def require_vendor_user(conn, _opts) do
    if Scope.vendor?(conn.assigns[:current_scope]) do
      conn
    else
      conn
      |> put_flash(:error, "Vendor access required.")
      |> redirect(to: signed_in_path(conn))
      |> halt()
    end
  end

  @doc """
  Plug for routes that require cashier access.
  """
  def require_cashier_user(conn, _opts) do
    if Scope.cashier?(conn.assigns[:current_scope]) do
      conn
    else
      conn
      |> put_flash(:error, "Cashier access required.")
      |> redirect(to: signed_in_path(conn))
      |> halt()
    end
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :user_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn
end
