defmodule RiverSideWeb.UserSessionController do
  @moduledoc """
  Controller for handling user authentication sessions.

  This controller manages the magic link authentication flow, allowing users
  to log in without passwords. It handles both regular login and confirmed
  user login (when a user clicks a confirmation link).

  ## Authentication Flow

  1. User requests a magic link via email
  2. System sends email with time-limited token
  3. User clicks link, which includes the token
  4. Controller validates token and creates session
  5. Previous sessions are disconnected for security

  ## Security Features

  * Tokens expire after 20 minutes
  * One-time use tokens (consumed on successful login)
  * Previous sessions disconnected on new login
  * Invalid tokens show generic error message
  """
  use RiverSideWeb, :controller

  alias RiverSide.Accounts
  alias RiverSideWeb.UserAuth

  @doc """
  Creates a new user session for confirmed users.

  This action is triggered when a user clicks on a confirmation link
  from their email. It logs them in and shows a confirmation message.

  ## Parameters

  * `conn` - The connection struct
  * `params` - Must include `"_action" => "confirmed"` and user token

  ## Returns

  Delegates to private `create/3` with confirmation message.
  """
  def create(conn, %{"_action" => "confirmed"} = params) do
    create(conn, params, "User confirmed successfully.")
  end

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  # Handles the actual magic link authentication
  #
  # Validates the token, creates the session, and disconnects any
  # previous sessions for security. Shows appropriate flash messages
  # based on success or failure.
  #
  # ## Security Notes
  #
  # * Tokens are single-use and deleted after successful login
  # * Generic error message prevents token enumeration
  # * All previous sessions are invalidated on new login
  defp create(conn, %{"user" => %{"token" => token} = user_params}, info) do
    case Accounts.login_user_by_magic_link(token) do
      {:ok, {user, tokens_to_disconnect}} ->
        # Disconnect all other sessions for this user
        UserAuth.disconnect_sessions(tokens_to_disconnect)

        conn
        |> put_flash(:info, info)
        |> UserAuth.log_in_user(user, user_params)

      _ ->
        # Generic error to prevent token enumeration attacks
        conn
        |> put_flash(:error, "The link is invalid or it has expired.")
        |> redirect(to: ~p"/users/log-in")
    end
  end

  @doc """
  Deletes the current user session (logs out).

  Clears the user's session and authentication tokens, effectively
  logging them out of the system.

  ## Parameters

  * `conn` - The connection struct
  * `_params` - Unused request parameters

  ## Returns

  Redirects to home page with logout confirmation message.

  ## Side Effects

  * Deletes session token from database
  * Clears session cookie
  * Clears remember me cookie if present
  """
  def delete(conn, _params) do
    if conn.assigns[:current_scope] && conn.assigns.current_scope do
      conn
      |> put_flash(:info, "Logged out successfully.")
      |> UserAuth.log_out_user()
    else
      conn
      |> put_flash(:error, "You are not logged in.")
      |> redirect(to: ~p"/")
    end
  end
end
