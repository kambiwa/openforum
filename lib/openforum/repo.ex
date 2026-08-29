defmodule Openforum.Repo do
  use Ecto.Repo,
    otp_app: :openforum,
    adapter: Ecto.Adapters.Postgres

  use Scrivener, page_size: 10, max_page_size: 100
end
