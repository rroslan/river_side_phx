defmodule RiverSide.Accounts.UserNotifier do
  import Swoosh.Email

  alias RiverSide.Mailer
  alias RiverSide.Accounts.User

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"River Side Food Court", "noreply@applikasi.tech"})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    deliver(user.email, "Update your email - River Side Food Court", """
    Hi #{user.email},

    You requested to change your email address for your River Side Food Court account.

    Please click the link below to confirm your new email:
    #{url}

    This link will expire in 24 hours.

    If you didn't request this change, please ignore this email or contact our support team.

    Best regards,
    River Side Food Court Team
    """)
  end

  @doc """
  Deliver instructions to log in with a magic link.
  """
  def deliver_login_instructions(user, url) do
    case user do
      %User{confirmed_at: nil} -> deliver_confirmation_instructions(user, url)
      _ -> deliver_magic_link_instructions(user, url)
    end
  end

  defp deliver_magic_link_instructions(user, url) do
    deliver(user.email, "Your login link - River Side Food Court", """
    Hi #{user.email},

    Welcome back to River Side Food Court!

    Click the secure link below to log into your account:
    #{url}

    This magic link will expire in 10 minutes for your security.

    If you didn't request this login link, you can safely ignore this email.

    Enjoy your meal!
    River Side Food Court Team
    """)
  end

  defp deliver_confirmation_instructions(user, url) do
    deliver(user.email, "Welcome to River Side Food Court - Please confirm your email", """
    Hi #{user.email},

    Welcome to River Side Food Court! We're excited to have you join us.

    Please confirm your email address by clicking the link below:
    #{url}

    Once confirmed, you'll be able to:
    • Browse menus from all our vendors
    • Place orders for pickup
    • Track your order status in real-time
    • Save your favorite items

    This link will expire in 24 hours.

    If you didn't create an account with us, please ignore this email.

    See you soon!
    River Side Food Court Team
    """)
  end
end
