defmodule CreditForecast.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      CreditForecast.Repo,
      # Start the Telemetry supervisor
      CreditForecastWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: CreditForecast.PubSub},
      # Start the Endpoint (http/https)
      CreditForecastWeb.Endpoint,
      # Start a worker by calling: CreditForecast.Worker.start_link(arg)
      # {CreditForecast.Worker, arg}
      {DynamicSupervisor, strategy: :one_for_one, name: CreditForecast.QuerySupervisor},
      {Registry, keys: :unique, name: CreditForecast.QueryRegistry}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CreditForecast.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CreditForecastWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
