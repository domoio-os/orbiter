defmodule Orbiter.Connection do
  require Lager

  alias Orbiter.{Config, PublicKey, ConnectionManager, DeviceState}

  @server Application.get_env(:orbiter, :server)
  @port Application.get_env(:orbiter, :port)


  # callbacks
  #----------------------------------------------------------------------

  def start(manager) do
    Lager.info "Connecting to the server."
    case connect(manager) do
      :error -> :error
      {:ok, socket} ->
        loop(socket, manager)
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

  defp send_msg(socket, msg) do
    Lager.info "Sending msg: ~p", [msg]
    packed = :msgpack.pack msg
    :ssl.send socket, packed
  end

  defp loop(socket, manager) do
    receive do
      {:ssl, _socket, packed_data} ->
        {:ok, data} = :msgpack.unpack packed_data


        route(data)
        loop(socket, manager)
      {:ssl_closed, _} ->
        Lager.info "Disconnected"
      {:ssl_error, _} ->
        Lager.info "SSL Error"
      {:send_msg, msg} ->
        send_msg(socket, msg)
        loop(socket, manager)
      other ->
        Lager.info "Received: ~p", [other]
        loop(socket, manager)
    end
  end


  def route(%{"t" => type, "d" => data}) do
    route(type, data)
  end

  def route(%{"action" => "hello", "device" => data}) do
    device = Orbiter.Device.extrude! data
    DeviceState.init_device device
    ConnectionManager.connected
  end

  def route(%{"action" => "set", "device_id" => device_id, "port_id" => port_id, "value" => value}) do
    DeviceState.set_port device_id, port_id, value
  end


  def route(command, data) do
    Lager.info "Invalid message: ~p => ~p", [command, data]
  end
end
