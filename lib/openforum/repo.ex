defmodule Openforum.Repo do
  use Ecto.Repo,
    otp_app: :openforum,
    adapter: Ecto.Adapters.Postgres
end
