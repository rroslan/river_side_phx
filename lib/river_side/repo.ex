defmodule RiverSide.Repo do
  use Ecto.Repo,
    otp_app: :river_side,
    adapter: Ecto.Adapters.Postgres
end
