defmodule Openforum.WorkFlowStep do
  use Ecto.Schema
  import Ecto.Changeset

  schema "work_flow_steps" do
    field :name, :string
    field :description, :string
    field :order_index, :integer, default: 0

    belongs_to :work_flow, Openforum.WorkFlow
    belongs_to :role, Openforum.Role

    timestamps(type: :utc_datetime)
  end

  def changeset(step, attrs) do
    step
    |> cast(attrs, [:name, :description, :order_index, :work_flow_id, :role_id])
    |> validate_required([:name, :work_flow_id, :order_index])
    |> validate_length(:name, min: 1, max: 160)
    |> foreign_key_constraint(:work_flow_id)
    |> foreign_key_constraint(:role_id)
  end
end
