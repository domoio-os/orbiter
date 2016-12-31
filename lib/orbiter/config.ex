defmodule Orbiter.Config do
  require Lager
  use GenServer
  use Extruder

  @server_name Orbiter.Config
  @config_dir Application.get_env(:orbiter, :config_dir)
  @config_file "#{@config_dir}/config"

  defmodel do
    field :hardware_id, :string
  end

  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: @server_name)
  end

  def get(key) do
    GenServer.call @server_name, {:get, key}
  end

  def set(key, value) do
    GenServer.call @server_name, {:set, key, value}
  end

  def all() do
    GenServer.call @server_name, :all
  end

  # callbacks
  #----------------------------------------------------------------------

  def init(:ok) do
    config = read_config
    {:ok, config}
  end

  def handle_call({:get, key}, _from, config) do
    value = Map.fetch! config, key
    {:reply, value, config}
  end

  def handle_call({:set, key, value}, _from, config) do
    config = Map.put config, key, value
    :ok = save_config(config)
    {:reply, value, config}
  end

  def handle_call(:all, _from, config) do
    {:reply, config, config}
  end

  defp read_config do
    case File.read @config_file do
      {:ok, content} -> Poison.decode!(content) |> Orbiter.Config.extrude!
      {:error, _} -> create_config
    end
  end

  defp create_config do
    initial_config = %Orbiter.Config{}
    save_config(initial_config)
    initial_config
  end

  defp save_config(config) do
    json = Poison.encode! config
    case File.write(@config_file, json, [:write]) do
      :ok -> :ok
      {:error, error} -> raise "Error :#{error} writing config file #{@config_file}"
    end
  end

end
