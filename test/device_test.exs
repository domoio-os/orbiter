defmodule DeviceTest do
  use ExUnit.Case

  test "change_port" do
    SpecServer.start()
    Application.stop(:orbiter)
    Application.start(:orbiter)
    assert_receive :connected, 1000

    Orbiter.Device.change_port "in", 1
    assert_receive {:msg, %{"action" => "state_changed", "port" => "in", "value" => 1}}
  end



end
