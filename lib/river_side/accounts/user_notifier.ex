defmodule RiverSide.Accounts.UserNotifier do
  import Swoosh.Email

  alias RiverSide.Mailer
  alias RiverSide.Accounts.User

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, html_body) do
    email =
      new()
      |> to(recipient)
      |> from({"River Side Food Court", "noreply@applikasi.tech"})
      |> subject(subject)
      |> html_body(html_body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  # Base HTML template with dark mode support
  defp html_template(content) do
    """
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <meta name="color-scheme" content="light dark">
      <meta name="supported-color-schemes" content="light dark">
      <title>River Side Food Court</title>
      <style>
        :root {
          color-scheme: light dark;
          supported-color-schemes: light dark;
        }

        @media (prefers-color-scheme: dark) {
          body {
            background-color: #1a1a1a !important;
            color: #ffffff !important;
          }
          .container {
            background-color: #2d2d2d !important;
            border-color: #404040 !important;
          }
          .header {
            background-color: #374151 !important;
            border-bottom-color: #4b5563 !important;
          }
          h1, h2, h3 {
            color: #ffffff !important;
          }
          .button {
            background-color: #10b981 !important;
            color: #ffffff !important;
          }
          .button:hover {
            background-color: #059669 !important;
          }
          .footer {
            color: #9ca3af !important;
          }
          .feature-item {
            color: #d1d5db !important;
          }
        }

        body {
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
          line-height: 1.6;
          color: #333333;
          background-color: #f3f4f6;
          margin: 0;
          padding: 0;
        }

        .wrapper {
          background-color: #f3f4f6;
          padding: 20px;
        }

        .container {
          max-width: 600px;
          margin: 0 auto;
          background-color: #ffffff;
          border-radius: 8px;
          box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
          overflow: hidden;
          border: 1px solid #e5e7eb;
        }

        .header {
          background-color: #1f2937;
          color: #ffffff;
          padding: 30px;
          text-align: center;
          border-bottom: 3px solid #10b981;
        }

        .header h1 {
          margin: 0;
          font-size: 28px;
          font-weight: 700;
          color: #ffffff;
        }

        .logo {
          width: 60px;
          height: 60px;
          margin-bottom: 10px;
        }

        .content {
          padding: 30px;
        }

        .greeting {
          font-size: 18px;
          margin-bottom: 20px;
        }

        .message {
          margin-bottom: 30px;
          line-height: 1.8;
        }

        .button {
          display: inline-block;
          padding: 14px 30px;
          background-color: #10b981;
          color: #ffffff;
          text-decoration: none;
          border-radius: 6px;
          font-weight: 600;
          font-size: 16px;
          margin: 20px 0;
        }

        .button:hover {
          background-color: #059669;
        }

        .features {
          margin: 20px 0;
          padding: 20px;
          background-color: #f9fafb;
          border-radius: 6px;
        }

        .feature-item {
          padding: 5px 0;
          color: #4b5563;
        }

        .footer {
          padding: 20px 30px;
          text-align: center;
          font-size: 14px;
          color: #6b7280;
          border-top: 1px solid #e5e7eb;
        }

        .warning {
          color: #dc2626;
          font-size: 14px;
          margin-top: 20px;
        }

        .expires {
          background-color: #fef3c7;
          border: 1px solid #fbbf24;
          color: #92400e;
          padding: 10px 15px;
          border-radius: 6px;
          font-size: 14px;
          margin: 20px 0;
        }

        @media (prefers-color-scheme: dark) {
          .features {
            background-color: #374151 !important;
          }
          .expires {
            background-color: #78350f !important;
            border-color: #f59e0b !important;
            color: #fef3c7 !important;
          }
        }
      </style>
    </head>
    <body>
      <div class="wrapper">
        <div class="container">
          <div class="header">
            <svg class="logo" viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
              <circle cx="50" cy="50" r="45" fill="#10b981"/>
              <path d="M25 50 Q35 30, 50 50 T75 50" stroke="#ffffff" stroke-width="3" fill="none"/>
              <path d="M25 55 Q35 35, 50 55 T75 55" stroke="#ffffff" stroke-width="3" fill="none"/>
              <path d="M30 40 L30 25 Q30 20, 35 20 L40 20 Q45 20, 45 25 L45 40" stroke="#ffffff" stroke-width="3" fill="none"/>
              <circle cx="65" cy="35" r="12" fill="none" stroke="#ffffff" stroke-width="3"/>
              <line x1="60" y1="35" x2="70" y2="35" stroke="#ffffff" stroke-width="2"/>
              <line x1="65" y1="30" x2="65" y2="40" stroke="#ffffff" stroke-width="2"/>
            </svg>
            <h1>River Side Food Court</h1>
          </div>
          #{content}
        </div>
      </div>
    </body>
    </html>
    """
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    html_body =
      html_template("""
        <div class="content">
          <p class="greeting">Hi #{user.email},</p>

          <p class="message">
            You requested to change your email address for your River Side Food Court account.
          </p>

          <div style="text-align: center;">
            <a href="#{url}" class="button">Confirm New Email</a>
          </div>

          <div class="expires">
            ⏰ This link will expire in 24 hours
          </div>

          <p class="warning">
            If you didn't request this change, please ignore this email or contact our support team.
          </p>
        </div>

        <div class="footer">
          <p>Best regards,<br>River Side Food Court Team</p>
          <p style="margin-top: 10px; font-size: 12px;">
            © 2024 River Side Food Court. All rights reserved.
          </p>
        </div>
      """)

    deliver(user.email, "Update your email - River Side Food Court", html_body)
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
    html_body =
      html_template("""
        <div class="content">
          <p class="greeting">Hi #{user.email},</p>

          <p class="message">
            Welcome back to River Side Food Court!
          </p>

          <div style="text-align: center;">
            <a href="#{url}" class="button">Log In to Your Account</a>
          </div>

          <div class="expires">
            ⏰ This magic link will expire in 10 minutes for your security
          </div>

          <p style="font-size: 14px; color: #6b7280; margin-top: 20px;">
            If you didn't request this login link, you can safely ignore this email.
          </p>
        </div>

        <div class="footer">
          <p>Enjoy your meal! 🍽️<br>River Side Food Court Team</p>
          <p style="margin-top: 10px; font-size: 12px;">
            © 2024 River Side Food Court. All rights reserved.
          </p>
        </div>
      """)

    deliver(user.email, "Your login link - River Side Food Court", html_body)
  end

  defp deliver_confirmation_instructions(user, url) do
    html_body =
      html_template("""
        <div class="content">
          <p class="greeting">Hi #{user.email},</p>

          <p class="message">
            Welcome to River Side Food Court! We're excited to have you join us. 🎉
          </p>

          <div style="text-align: center;">
            <a href="#{url}" class="button">Confirm Your Email</a>
          </div>

          <div class="features">
            <p style="font-weight: 600; margin-bottom: 10px;">Once confirmed, you'll be able to:</p>
            <div class="feature-item">✓ Browse menus from all our vendors</div>
            <div class="feature-item">✓ Place orders for pickup</div>
            <div class="feature-item">✓ Track your order status in real-time</div>
            <div class="feature-item">✓ Save your favorite items</div>
          </div>

          <div class="expires">
            ⏰ This link will expire in 24 hours
          </div>

          <p style="font-size: 14px; color: #6b7280; margin-top: 20px;">
            If you didn't create an account with us, please ignore this email.
          </p>
        </div>

        <div class="footer">
          <p>See you soon! 👋<br>River Side Food Court Team</p>
          <p style="margin-top: 10px; font-size: 12px;">
            © 2024 River Side Food Court. All rights reserved.
          </p>
        </div>
      """)

    deliver(
      user.email,
      "Welcome to River Side Food Court - Please confirm your email",
      html_body
    )
  end
end
