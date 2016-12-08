defmodule Orbiter.Drivers.Gpio do
  @behaviour Orbiter.Driver
  require Lager
  # port config
  #----------------------------------------------------------------------

  def setup_port(_device, %Orbiter.Device.Port{id: id, input: true}) do
    {port_id, ""} = Integer.parse id
    {:ok, pid} = Gpio.start_link(port_id, :input)
    :ok = Gpio.set_int(pid, :both)
    {:ok, pid}
  end

  def setup_port(_device, %Orbiter.Device.Port{id: id, input: false}) do
    {port_id, ""} = Integer.parse id
    Gpio.start_link(port_id, :output)
  end

  def set_port(pid, value) do
    Gpio.write(pid, value)
  end

  def handle_info({port, reason}, state) do
    Lager.info "handle_info: [~p] [~p]", [port ,reason]
    {:noreply, state}
  end

end
