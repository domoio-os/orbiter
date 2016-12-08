defmodule Orbiter.Driver do
  @callback setup_port(Orbiter.Device.t, Orbiter.Device.Port.t) :: {:ok, Pid}
  @callback set_port(Pid.t, Integer.t) :: :ok
end
