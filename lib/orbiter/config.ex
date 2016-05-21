defmodule Orbiter.Config do
  require Lager
  use GenServer

  @server_name Orbiter.Config

  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: @server_name)
  end

  def get(key) do
    GenServer.call @server_name, {:get, key}
  end

  # callbacks
  #----------------------------------------------------------------------

  def init(:ok) do
    config = read_config
    {:ok, config}
  end

  def handle_call({:get, key}, _from, config) do
    value = config[key]
    {:reply, value, config}
  end

  defp read_config do
    config = Mix.Config.read! Application.get_env(:orbiter, :config_file)
    config[:orbiter]
  end
end
