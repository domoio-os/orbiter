defmodule Orbiter.ConnectionManager do
  require Lager
  use GenServer
  import Supervisor.Spec

  defmodule ConnectionState do
    defstruct connected: false, connection: nil, last_error: nil
  end

  @server_name ConnectionManager

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: @server_name)
  end

  def send_msg(msg) do
    GenServer.call(@server_name, {:send_msg, msg})
  end

  def connected do
    GenServer.call(@server_name, :connected)
  end

  def state() do
    GenServer.call(@server_name, :get_state)
  end

  def start_connection() do
    GenServer.call(@server_name, :start_connection)
  end

  # callbacks
  #----------------------------------------------------------------------

  def init(:ok) do
    state = %ConnectionState{}
    state = start_connection(state)
    {:ok, state}
  end

  defp start_connection(state) do
    case Orbiter.Config.get(:hardware_id) do
      nil -> state
      hardware_id -> connect(state)
    end
  end

  defp connect(state) do
    {:ok, pid} = Task.Supervisor.start_child(Orbiter.TaskSupervisor, Orbiter.Connection, :start, [self()])
    Process.monitor(pid)
    state = %ConnectionState{connection: pid}
  end

  def handle_call(:get_state, _from, state) do
    connected = state.connection != nil
    configured = Orbiter.Config.get(:hardware_id) != nil
    {:reply, %{connected: connected, configured: configured}, state}
  end

  def handle_call(:start_connection, _from, state) do
    state = start_connection(state)
    {:reply, :ok, state}
  end

  def handle_call({:send_msg, msg}, _from, state) do
    send(state.connection, {:send_msg, msg})
    {:reply, :ok, state}
  end

  def handle_call(:connected, _from, state) do
    state = %{state | connected: true}
    {:reply, :ok, state}
  end


  # Events handling
  #----------------------------------------------------------------------

  def handle_info(:reconnect, state) do
    state = connect(state)
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
