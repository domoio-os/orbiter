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
    :ssl.send(socket, Orbiter.Config.get :hardware_id)
    private_key = RSA.load_key("#{Application.get_env(:orbiter, :certs_root)}/orbiter.pem")
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
      {:ssl, _socket, data} ->
        Lager.info "Received: ~p", [data]
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


end
