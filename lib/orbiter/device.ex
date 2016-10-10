defmodule Orbiter.Device do
  use Extruder

  defmodule Port do
    use Extruder

    defmodel do
      field :id, :string
      field :input, :boolean
      field :digital, :boolean
      field :flow, :atom
      field :value, :int, default: 0

      validates_inclussion_of :flow, in: [:push, :pull]
    end
  end


  defmodel do
    field :id, :string
    field :project_id, :string
    field :ports, :structs_list, module: Port
  end

  def change_port(port, value) do
    Orbiter.ConnectionManager.send_msg %{"action" => "state_changed", "port" => port, "value" => value}
  end

end
