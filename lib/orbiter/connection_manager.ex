defmodule Orbiter.ConnectionManager do
  require Lager
  use GenServer
  import Supervisor.Spec

  defmodule ConnectionState do
    defstruct connection: nil, last_error: nil
  end

  @server_name ConnectionManager

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: @server_name)
  end

  def send_msg(msg) do
    GenServer.call(@server_name, {:send_msg, msg})
  end

  # callbacks
  #----------------------------------------------------------------------

  def init(:ok) do
    {:ok, connection} = connect()
    {:ok, %ConnectionState{connection: connection} }
  end

  defp connect() do
    {:ok, pid} = Task.Supervisor.start_child(Orbiter.TaskSupervisor, Orbiter.Connection, :start, [self()])
    Process.monitor(pid)
    {:ok, pid}
  end

  def handle_call({:send_msg, msg}, _from, state) do
    send(state.connection, {:send_msg, msg})
    {:reply, :ok, state}
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
        Process.send_after self(), :reconnect, 5000
      nil ->
        Process.send_after self(), :reconnect, 1000
    end
    state = %{state | connection: nil}
    {:noreply, state}
  end

end
