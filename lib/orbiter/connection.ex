defmodule Orbiter.Connection do
  require Lager

  alias Orbiter.{Config, ConnectionManager, DeviceState}

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


  # defp handsake(socket) do
  #   {:ok, hardware_id} = Config.get(:hardware_id)
  #   :ssl.send(socket, hardware_id)

  #   config_dir = Application.get_env(:orbiter, :config_dir)
  #   private_file = "#{config_dir}/certs/orbiter.pem"
  #   private_key = RSA.load_key(private_file)
  #   {:ok, crypted_nounce} = :ssl.recv(socket, 0)
  #   nounce = RSA.decrypt(crypted_nounce, {:private, private_key})
  #   :ssl.send(socket, nounce)
  #   {:ok, "OK"} = :ssl.recv(socket, 0)
  #   :ssl.setopts(socket, [{:active, true}])
  #   {:ok, socket}
  # end


  defp handsake(socket) do
    Lager.info "Starting handsake"
    hardware_id = Config.get(:hardware_id)
    secret = Config.get :secret
    auth = :msgpack.pack %{hardware_id: hardware_id, secret: secret}
    :ssl.send(socket, auth)
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
        Lage.info "Received: ~p", [other]
        loop(socket, manager)
    end
  end


  def route(%{"t" => type, "d" => data}) do
    route(type, data)
  end

  def route("hello", data) do
    device = Orbiter.Device.extrude! data
    DeviceState.init_device device
    ConnectionManager.connected
  end

  def route("command", %{"action" => "set", "device_id" => device_id, "port_id" => port_id, "value" => value}) do
    DeviceState.set_port device_id, port_id, value
  end


  def route(command, data) do
    Lager.info "Invalid message: ~p => ~p", [command, data]
  end
end
