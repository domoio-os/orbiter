defmodule Orbiter.Gpio do
  require Lager
  use GenServer

  @server_name GPIO

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: @server_name)
  end

  # callbacks
  #----------------------------------------------------------------------

  def init(:ok) do
  end

  def handle_info({:ssl, _, msg}, state) do
    Lager.info "Received: ~p", [msg]
    {:noreply, state}
  end


end
