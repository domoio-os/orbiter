defmodule Orbiter.Connection do
  require Lager

  alias Orbiter.RSA

  @server_name Connection


  # callbacks
  #----------------------------------------------------------------------

  def start(manager) do
    Lager.info "Connecting to the server."
    case connect(manager) do
      :error -> :error
      {:ok, socket} -> loop(socket, manager)
    end
  end

  defp connect(manager) do
    port = Orbiter.Config.get :port
    server = Orbiter.Config.get :server
    :ssl.start()
    case :ssl.connect(server, port,  [:binary, packet: 2, active: false, reuseaddr: true], :infinity) do
      {:ok, socket} -> handsake(socket)
      {:error, cause} ->
        send(manager, {:connection_error, cause})
        :error
    end
  end


  defp handsake(socket) do
    {:ok, device_id} = Orbiter.Config.device_id
    :ssl.send(socket, device_id)

    config_dir = Application.get_env(:orbiter, :config_dir)
    private_file = "#{config_dir}/certs/orbiter.pem"
    private_key = RSA.load_key(private_file)
    {:ok, crypted_nounce} = :ssl.recv(socket, 0)
    nounce = RSA.decrypt(crypted_nounce, {:private, private_key})
    :ssl.send(socket, nounce)
    {:ok, "OK"} = :ssl.recv(socket, 0)
    :ssl.setopts(socket, [{:active, true}])
    {:ok, socket}
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
    Orbiter.ConnectionManager.connected(device)
  end

  def route(command, data) do
    Lager.info "Invalid message: ~p => ~p", [command, data]
  end
end
