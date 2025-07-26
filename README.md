# RiverSide

To start your Phoenix server:

* Run `mix setup` to install and setup dependencies
* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Authentication

This application uses magic link authentication (passwordless). Users log in by:
1. Entering their email address
2. Receiving a magic link via email
3. Clicking the link to authenticate

## User Roles

The system supports three user roles:
- **Admin** (`is_admin`): Full system access
- **Vendor** (`is_vendor`): Vendor-specific functionality
- **Cashier** (`is_cashier`): Cashier-specific functionality

## Database Setup

1. Copy `.env.example` to `.env` and configure your environment variables:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` to set your user emails:
   ```
   ADMIN_EMAIL=rroslan@gmail.com
   VENDOR_EMAIL=roslanr@gmail.com
   CASHIER_EMAIL=rosslann.ramli@gmail.com
   ```

3. Run migrations:
   ```bash
   mix ecto.migrate
   ```

4. Seed the database with initial users:
   ```bash
   mix run priv/repo/seeds.exs
   ```

The seed script will create three users with the emails specified in your `.env` file, each with their respective role.

## Post-Setup Instructions

After making these changes:

1. Clean dependencies and recompile:
   ```bash
   mix deps.clean --all
   mix deps.get
   mix compile
   ```

2. Run the migrations:
   ```bash
   mix ecto.migrate
   ```

3. Run the seed script:
   ```bash
   mix run priv/repo/seeds.exs
   ```

4. Start the server:
   ```bash
   mix phx.server
   ```

## Important Notes

- **No passwords**: This application uses passwordless authentication via magic links only
- **Email configuration**: Make sure your mail adapter is properly configured for magic links to work
- **Local development**: If using the local mail adapter, visit `/dev/mailbox` to see sent emails
- **User roles**: Each user can have one or more roles (admin, vendor, cashier)

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

* Official website: https://www.phoenixframework.org/
* Guides: https://hexdocs.pm/phoenix/overview.html
* Docs: https://hexdocs.pm/phoenix
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix
