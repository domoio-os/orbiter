defmodule Orbiter do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    children = [
      supervisor(Task.Supervisor, [[name: Orbiter.TaskSupervisor]]),
      worker(Orbiter.Config, []),
      worker(Orbiter.ConnectionManager, [])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Orbiter.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
