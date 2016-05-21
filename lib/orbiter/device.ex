defmodule Orbiter.Device do
  def change_port(port, value) do
    Orbiter.ConnectionManager.send_msg %{"action" => "state_changed", "port" => port, "value" => value}
  end
end
