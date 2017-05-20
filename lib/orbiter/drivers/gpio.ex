defmodule Orbiter.Drivers.Gpio do
  @behaviour Orbiter.Driver
  require Lager
  # port config
  #----------------------------------------------------------------------

  def setup_port(_device, %Orbiter.Device.Port{id: id, io: :input}) do
    {port_id, ""} = Integer.parse id
    Lager.info "Setup output port:  #{port_id}"
    {:ok, pid} = Gpio.start_link(port_id, :input)
    :ok = Gpio.set_int(pid, :both)
    {:ok, pid}
  end

  def setup_port(_device, %Orbiter.Device.Port{id: id, io: :output}) do
    {port_id, ""} = Integer.parse id
    Gpio.start_link(port_id, :output)
  end

  def set_port(pid, value) do
    Gpio.write(pid, value)
  end

  def handle_info({:gpio_interrupt, port, reason}, state) do
    Lager.info "handle_info: [~p] [~p]", [port ,reason]
    {:noreply, state}
  end

  def handle_info(args, state) do
    IO.puts "fooo #{inspect(args)}"
    {:noreply, state}
  end
end
