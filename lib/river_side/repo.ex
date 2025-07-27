defmodule RiverSide.Repo do
  @moduledoc """
  The repository module for database interactions in River Side Food Court.

  This module is the main interface to the PostgreSQL database and provides
  the foundation for all data persistence operations in the system.

  ## Usage

  The Repo module is used throughout the application for:

  * **User Management** - User accounts, authentication tokens, and roles
  * **Vendor Operations** - Vendor profiles, menu items, and availability
  * **Order Processing** - Order creation, updates, and status tracking
  * **Table Management** - Table availability and customer sessions

  ## Common Operations

      # Fetch a single record
      Repo.get(User, user_id)

      # Query with conditions
      Repo.all(from v in Vendor, where: v.is_active == true)

      # Insert new record
      Repo.insert(changeset)

      # Update existing record
      Repo.update(changeset)

      # Delete record
      Repo.delete(record)

      # Transactions
      Repo.transaction(fn ->
        # Multiple operations
      end)

  ## Configuration

  Database configuration is managed in:
  * `config/dev.exs` - Development database
  * `config/test.exs` - Test database (sandboxed)
  * `config/runtime.exs` - Production database (via DATABASE_URL)

  ## Performance Considerations

  * Connection pooling is configured for optimal performance
  * Preloading associations to avoid N+1 queries
  * Database indexes on frequently queried fields
  * Timeout settings for long-running queries

  ## Data Integrity

  The Repo enforces data integrity through:
  * Foreign key constraints at the database level
  * Unique constraints for emails, table numbers, etc.
  * Check constraints for valid enum values
  * Transactions for multi-table operations
  """
  use Ecto.Repo,
    otp_app: :river_side,
    adapter: Ecto.Adapters.Postgres
end
