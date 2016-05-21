defmodule SpecServer do
  require Lager

  def start(opt \\ [{:hardware_id, "123"}]) do
    pid = self
    Task.async(fn -> accept(pid, opt) end)
  end

  def accept(pid, opt) do
    port = Orbiter.Config.get :port

    certs_root =  Application.get_env(:orbiter, :server_certs_root)
    cert_file = "#{certs_root}/server.crt"
    key_file = "#{certs_root}/server.key"
    :ssl.start()

    {:ok, socket} = :ssl.listen(port, [:binary, packet: 2, active: false, reuseaddr: true, certfile: cert_file, keyfile: key_file ])
    {:ok, client} = :ssl.transport_accept(socket)
    :ok = :ssl.ssl_accept(client)
    :ok = handsake(client, pid, opt)
    server_loop(client, pid)

  end

  defp handsake(socket, pid, opt) do
    hardware_id = opt[:hardware_id]
    {:ok, ^hardware_id} = :ssl.recv(socket, 0)
    nounce = :crypto.rand_bytes(40)
    device_public_key = Orbiter.RSA.load_key("#{Application.get_env(:orbiter, :certs_root)}/orbiter.pub.pem")

    encrypted_nounce = Orbiter.RSA.encrypt(nounce, {:public, device_public_key})
    :ssl.send(socket, encrypted_nounce)

    {:ok, received_nounce} = :ssl.recv(socket, 0)
    if nounce == received_nounce do
      :ssl.send(socket, "OK")
      :ssl.setopts(socket, [{:active, true}])
      send pid, :connected
      :ok
    else
      send pid, :handsare_error
      :error
    end
  end

  defp server_loop(socket, pid) do
    receive do
      {:ssl, _socket, data} ->
        {:ok, msg} = :msgpack.unpack data
        send pid, {:msg, msg}
        server_loop(socket, pid)
      {:ssl_closed, _} ->
        send pid, :disconnected
        # DomoioProtocol.Domoio.disconnect_device(state, :ssl_closed)
      {:ssl_error, _} ->
        send pid, :ssl_error
    end
  end
end

ExUnit.start()
