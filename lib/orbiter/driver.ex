defmodule Orbiter.Driver do
   @callback setup_port(Orbiter.Device.Port.t) :: {:ok, Pid}
end
