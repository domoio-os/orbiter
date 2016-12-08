defmodule Orbiter.Drivers.Dummy do
  require Lager

  @behaviour Orbiter.Driver

  # port config
  #----------------------------------------------------------------------

  def setup_port(device, port) do
    IO.puts "configuring #{device.id}, #{inspect port}"
    {:ok, self}
  end

  def set_port(pid, value) do
    Lager.info "Port set: ~p", [value]
  end
end
