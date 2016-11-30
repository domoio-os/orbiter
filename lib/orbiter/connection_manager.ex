defmodule Orbiter.ConnectionManager do
  require Lager
  use GenServer
  import Supervisor.Spec

  defmodule ConnectionState do
    defstruct driver: nil, connection: nil, last_error: nil, device: nil, ports: %{}
  end

  @server_name ConnectionManager

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: @server_name)
  end

  def send_msg(msg) do
    GenServer.call(@server_name, {:send_msg, msg})
  end

  def connected(device) do
    GenServer.call(@server_name, {:connected, device})
  end

  def state() do
    GenServer.call(@server_name, :get_state)
  end

  # callbacks
  #----------------------------------------------------------------------

  def init(:ok) do
    {:ok, connection} = connect()

    # Get the default driver
    driver = Application.get_env(:orbiter, :driver)
    state = %ConnectionState{ driver: driver }
    {:ok, state}
  end

  defp connect() do
    {:ok, pid} = Task.Supervisor.start_child(Orbiter.TaskSupervisor, Orbiter.Connection, :start, [self()])
    Process.monitor(pid)
    {:ok, pid}
  end

  def handle_call(:get_state, _from, state) do
    connected = state.connection != nil
    {:reply, %{connected: connected, configured: false}, state}
  end


  def handle_call({:send_msg, msg}, _from, state) do
    send(state.connection, {:send_msg, msg})
    {:reply, :ok, state}
  end

  def handle_call({:connected, device}, _from, state) do
    ports = build_ports(device, state)
    state = %{state | device: device}
    {:reply, :ok, state}
  end

  def build_ports(device, state) do
    Enum.reduce device.ports, %{}, fn(port, ports) ->
      {:ok, pid} = state.driver.setup_port port
    end
  end

  # Events handling
  #----------------------------------------------------------------------

  def handle_info(:reconnect, state) do
    {:ok, connection} = connect()
    state = %ConnectionState{connection: connection}
    {:noreply, state}
  end

  def handle_info({:connection_error, cause}, state) do
    state = %{state | last_error: :connection_error}
    {:noreply, state}
  end


  def handle_info({:DOWN, ref, :process, _pid, reason}, state) do
    Lager.info "Connection down ~p [~p]", [reason, state.last_error]
    case state.last_error do
      :connection_error ->
        Process.send_after self(), :reconnect, 10000
      nil ->
        Process.send_after self(), :reconnect, 5000
    end
    state = %{state | connection: nil}
    {:noreply, state}
  end

end
