defmodule Orbiter.Specs do
  use Extruder


  defmodel do
    field :ports, :structs_list, module: Port, default: []
  end

end
