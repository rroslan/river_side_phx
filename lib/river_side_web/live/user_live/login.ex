defmodule RiverSideWeb.UserLive.Login do
  use RiverSideWeb, :live_view

  alias RiverSide.Accounts

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-sm space-y-4">
        <div class="text-center">
          <.header>
            <p>Log in</p>
            <:subtitle>
              <%= if @current_scope && @current_scope.user do %>
                You need to reauthenticate to perform sensitive actions on your account.
              <% else %>
                Please log in with your email address to continue.
              <% end %>
            </:subtitle>
          </.header>
        </div>

        <div :if={local_mail_adapter?()} class="alert alert-info">
          <.icon name="hero-information-circle" class="size-6 shrink-0" />
          <div>
            <p>You are running the local mail adapter.</p>
            <p>
              To see sent emails, visit <.link href="/dev/mailbox" class="underline">the mailbox page</.link>.
            </p>
          </div>
        </div>

        <.form
          :let={f}
          for={@form}
          id="login_form_magic"
          action={~p"/users/log-in"}
          phx-submit="submit_magic"
        >
          <.input
            field={f[:email]}
            type="email"
            label="Email"
            autocomplete="username"
            required
            phx-mounted={JS.focus()}
          />
          <.button class="btn btn-primary w-full">
            Log in with email <span aria-hidden="true">→</span>
          </.button>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  def mount(_params, _session, socket) do
    # If user is already logged in, redirect to their dashboard
    case socket.assigns[:current_scope] do
      %{user: %{is_admin: true}} ->
        {:ok, push_navigate(socket, to: ~p"/admin/dashboard")}

      %{user: %{is_vendor: true}} ->
        {:ok, push_navigate(socket, to: ~p"/vendor/dashboard")}

      %{user: %{is_cashier: true}} ->
        {:ok, push_navigate(socket, to: ~p"/cashier/dashboard")}

      %{user: %{}} ->
        {:ok, push_navigate(socket, to: ~p"/users/settings")}

      _ ->
        # No user logged in, show login form
        email = Phoenix.Flash.get(socket.assigns.flash, :email)
        form = to_form(%{"email" => email}, as: "user")
        {:ok, assign(socket, form: form, trigger_submit: false)}
    end
  end

  def handle_event("submit_magic", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_login_instructions(
        user,
        &url(~p"/users/log-in/#{&1}")
      )
    end

    info =
      "If your email is in our system, you will receive instructions for logging in shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> push_navigate(to: ~p"/users/log-in")}
  end

  defp local_mail_adapter? do
    Application.get_env(:river_side, RiverSide.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
