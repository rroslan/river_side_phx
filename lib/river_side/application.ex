defmodule RiverSide.Application do
  @moduledoc """
  The RiverSide application supervisor.

  This module implements the Application behaviour and starts the
  supervision tree for the River Side Food Court system. It manages
  all the core services required for the application to function.

  ## Supervision Tree

  The application starts the following children in order:

  1. **Telemetry** - Metrics and monitoring infrastructure
  2. **Repo** - Database connection pool management
  3. **DNSCluster** - Node clustering for distributed deployments
  4. **PubSub** - Real-time messaging between processes and LiveViews
  5. **Endpoint** - HTTP server and WebSocket connections

  ## Configuration

  The application supports runtime configuration changes through
  the `config_change/3` callback, which propagates changes to the
  Phoenix endpoint.

  ## Real-time Features

  The PubSub system enables real-time updates for:
  - Order status changes across vendor and customer views
  - Table availability updates
  - Menu item changes
  - System-wide notifications
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      RiverSideWeb.Telemetry,
      RiverSide.Repo,
      {DNSCluster, query: Application.get_env(:river_side, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: RiverSide.PubSub},
      # Start a worker by calling: RiverSide.Worker.start_link(arg)
      # {RiverSide.Worker, arg},
      # Start to serve requests, typically the last entry
      RiverSideWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: RiverSide.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    RiverSideWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
