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

  def public_key do
    config_dir = Application.get_env(:orbiter, :config_dir)
    public_file = "#{config_dir}/certs/orbiter.pub.pem"

    case File.read(public_file) do
      {:ok, content} -> {:ok, content}
      {:error, error} -> raise "Error :#{error} loading public key #{public_file}"
    end

  end

  def device_id_file do
    config_dir = Application.get_env(:orbiter, :config_dir)
    "#{config_dir}/device_id"
  end

  def device_id do
    case File.read(device_id_file) do
      {:ok, content} -> {:ok, String.rstrip(content)}
      {:error, error} -> raise "Error :#{error} loading device id #{device_id_file}"
    end
  end


  def set_device_id(device_id) do
    case File.write(device_id_file, device_id, [:write]) do
      :ok -> :ok
      {:error, error} -> raise "Error :#{error} writing device file #{device_id_file}"
    end
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
    config_dir = Application.get_env(:orbiter, :config_dir)
    config = Mix.Config.read! "#{config_dir}/config.exs"
    config[:orbiter]
  end
end
