defmodule ConnectionTest do
  use ExUnit.Case

  test "connection to the server" do
    SpecServer.start()
    Application.stop(:orbiter)
    Application.start(:orbiter)

    assert_receive :connected, 1000
  end

  test "reconnect after server disconnection" do
    server_pid = SpecServer.start()
    Application.stop(:orbiter)
    Application.start(:orbiter)

    assert_receive :connected, 1000
    Task.shutdown server_pid
    server_pid = SpecServer.start()
    assert_receive :connected, 5000
  end

end
