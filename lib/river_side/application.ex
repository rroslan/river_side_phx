defmodule RiverSide.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

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
