defmodule Orbiter.Drivers.Dummy do
  @behaviour Orbiter.Driver

  # port config
  #----------------------------------------------------------------------

  def setup_port(device) do
    IO.puts "configuring #{device.id}"
    {:ok, self}
  end
end
