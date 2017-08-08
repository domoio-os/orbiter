defmodule Orbiter.Connection do
  require Lager

  alias Orbiter.{Config, PublicKey, ConnectionManager, DeviceState}

  defstruct manager: nil, last_seen: nil

  @server Application.get_env(:orbiter, :server)
  @port Application.get_env(:orbiter, :port)


  # callbacks
  #----------------------------------------------------------------------

  def start(manager) do
    Lager.info "Connecting to the server."
    case connect(manager) do
      :error -> :error
      {:ok, socket} ->
        state = %__MODULE__{manager: manager}

        state = set_last_seen(state)
        check_connection_state(state)
        watchdog_ping(socket)
        loop(socket, state)
    end
  end

  defp connect(manager) do
    :ssl.start()
    case :ssl.connect(@server, @port,  [:binary, packet: 2, active: false, reuseaddr: true], :infinity) do
      {:ok, socket} -> handsake(socket)
      {:error, cause} ->
        Lager.error "Error connecting: ~p" , [cause]
        send(manager, {:connection_error, cause})
        :error
    end
  end


  defp handsake(socket) do
    device_id = Config.get(:device_id)
    :ssl.send(socket, device_id)

    case :ssl.recv(socket, 0) do
      {:error, :closed} -> :error
      {:ok, crypted_nounce} ->
        nounce = PublicKey.decrypt crypted_nounce
        :ssl.send(socket, nounce)
        case :ssl.recv(socket, 0) do
          {:ok, "HELLO"} ->
            Lager.info "Device logged in"
            :ssl.setopts(socket, [{:active, true}])
            {:ok, socket}
          {:error, reason} ->
            Lager.error "Error connecting to server: ~p", [reason]
            :error
        end

    end
  end

  defp send_msg(socket, {action, data}) do
    packed = :msgpack.pack %{a: action, d: data}
    :ssl.send socket, packed
  end

  defp send_msg(socket, action) do
    packed = :msgpack.pack %{a: action}
    :ssl.send socket, packed
  end

  defp loop(socket, state) do
    receive do
      {:ssl, _socket, packed_data} ->
        {:ok, data} = :msgpack.unpack packed_data
        route(data)
        state = set_last_seen(state)
        loop(socket, state)
      {:send_msg, msg} ->
        send_msg(socket, msg)
        loop(socket, state)
      {:check_connection_state} ->
        case check_connection_state(state) do
          {:ok, state} -> loop(socket, state)
          :timeout ->
            Lager.info "Device timeout"
        end
      {:watchdog_ping} ->
        watchdog_ping(socket)
        loop(socket, state)

      {:ssl_closed, _} ->
        Lager.info "Disconnected"
      {:ssl_error, _} ->
        Lager.info "SSL Error"
      other ->
        Lager.info "Received: ~p", [other]
        loop(socket, state)
    end
  end

  defp set_last_seen(state) do
    {_, seconds, _} = :os.timestamp()
    %{state | last_seen: seconds}
  end

  defp check_connection_state(state) do
    {_, seconds, _} = :os.timestamp()
    if (seconds < state.last_seen + 16) do
      state_timer_pid = Process.send_after self(), {:check_connection_state}, 16000
      {:ok, state}
    else
      :timeout
    end
  end

  def watchdog_ping(socket) do
    :ok = send_msg socket, :ping
    Process.send_after self(), {:watchdog_ping}, 10000
  end


  def route(%{"action" => "hello", "device" => data}) do
    device = Orbiter.Device.extrude! data
    DeviceState.init_device device
    ConnectionManager.connected
  end

  def route(%{"action" => "set", "device_id" => device_id, "port_id" => port_id, "value" => value}) do
    DeviceState.set_port device_id, port_id, value
  end

  def route(%{"action" => "pong"}) do
  end


  def route(command) do
    Lager.info "Invalid message: ~p", [command]
  end
end
