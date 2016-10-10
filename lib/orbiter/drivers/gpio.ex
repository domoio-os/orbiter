defmodule Orbiter.Drivers.Gpio do
  @behaviour Orbiter.Driver

  # port config
  #----------------------------------------------------------------------

  def setup_port(%Orbiter.Device.Port{id: id, input: true}) do
    {port_id, ""} = Integer.parse id
    {:ok, pid} = Gpio.start_link(port_id, :input)
    :ok = Gpio.set_int(pid, :both)
    {:ok, pid}
  end

  def setup_port(%Orbiter.Device.Port{id: id, input: false}) do
    {port_id, ""} = Integer.parse id
    Gpio.start_link(port_id, :output)
  end
end
