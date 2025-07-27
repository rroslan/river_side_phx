defmodule RiverSide.Mailer do
  @moduledoc """
  Mailer module for sending emails in the River Side Food Court system.

  This module uses Swoosh to handle email delivery. It's primarily used
  for sending magic login links to users, but can be extended for other
  email notifications.

  ## Configuration

  The mailer is configured in `config/runtime.exs` and supports different
  adapters based on the environment:

  * **Development** - Uses Swoosh.Adapters.Local for viewing emails in browser
  * **Production** - Can be configured with SMTP or API-based adapters

  ## Usage Examples

      # Send a magic login link
      UserNotifier.deliver_magic_link(user, url)

      # Future: Send order confirmation
      OrderNotifier.deliver_order_confirmation(order)

  ## Email Types

  Currently supported email types:
  * Magic login links for passwordless authentication
  * System notifications (admin only)

  ## Security Considerations

  * All emails should use secure token generation
  * Login links expire after 20 minutes
  * Email templates sanitize user input
  * Production should use verified sender domains
  """
  use Swoosh.Mailer, otp_app: :river_side
end
