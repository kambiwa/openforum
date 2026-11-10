defmodule Openforum.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
    def start(_type, _args) do
      children = [
        OpenforumWeb.Telemetry,
        Openforum.Repo,
        {DNSCluster, query: Application.get_env(:openforum, :dns_cluster_query) || :ignore},
        {Phoenix.PubSub, name: Openforum.PubSub},
        {ChromicPDF, chromic_pdf_opts()},
        OpenforumWeb.Endpoint
      ]

          opts = [strategy: :one_for_one, name: Openforum.Supervisor]
      Supervisor.start_link(children, opts)
    end


    defp chromic_pdf_opts do
      base = [on_demand: true, no_sandbox: Application.get_env(:openforum, :chrome_no_sandbox, false)]

      case System.get_env("CHROME_PATH") do
        nil -> base
        path -> Keyword.put(base, :chrome_executable, path)
      end
    end


  @impl true
  def config_change(changed, _new, removed) do
    OpenforumWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
