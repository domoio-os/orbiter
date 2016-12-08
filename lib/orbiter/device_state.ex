defmodule Orbiter.DeviceState do
  use GenServer

  defstruct driver: nil, device: nil, port_pids: nil, driver: nil
  require Lager


  @server_name :device_state

  # Client API
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: @server_name)
  end

  def init_device(device) do
    GenServer.call @server_name, {:init, device}
  end

  def set_port(device_id, port_id, value) do
    GenServer.call @server_name, {:set_port, device_id, port_id, value}
  end

  # Server callbacks
  #----------------------------------------------------------------------

  def init([]) do
    devices = %{}
    {:ok, devices}
  end

  def handle_call({:init, device}, _from, devices) do
    driver = Application.get_env(:orbiter, :driver)
    ports = build_ports(device, driver)
    devices = Map.put devices, device.id, %Orbiter.DeviceState{device: device, port_pids: ports, driver: driver}
    {:reply, :ok, devices}
  end

  def handle_call({:set_port, device_id, port_id, value}, _from, devices) do
    case find(device_id, devices) do
      nil -> {:reply, {:error, :not_found}, devices}
      device ->
        device.driver.set_port device.port_pids[port_id], value
        {:reply, :ok, devices}
    end

  end

  defp find(device_id, states) do
    Map.get states, device_id, nil
  end

  defp build_ports(device, driver) do
    Enum.reduce device.ports, %{}, fn(port, ports) ->
      {:ok, pid} = driver.setup_port device, port
      Map.put ports, port.id, pid
    end
  end

end
