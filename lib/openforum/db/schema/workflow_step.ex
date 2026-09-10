defmodule Openforum.WorkFlowStep do
  use Ecto.Schema
  import Ecto.Changeset

  @stage_types [:draft, :reviewer, :approver]

  schema "work_flow_steps" do
    field :name, :string
    field :description, :string
    field :action, :string
    field :stage_type, Ecto.Enum, values: @stage_types
    field :order_index, :integer, default: 0

    belongs_to :work_flow, Openforum.WorkFlow
    belongs_to :role, OpenforumWeb.Schema.Role   # <-- was Openforum.Role

    timestamps(type: :utc_datetime)
  end

  def stage_types, do: @stage_types

  def changeset(step, attrs) do
    step
    |> cast(attrs, [:name, :description, :action, :stage_type, :order_index, :work_flow_id, :role_id])
    |> validate_required([:name, :stage_type, :work_flow_id, :role_id])
    |> validate_length(:name, min: 1, max: 160)
    |> foreign_key_constraint(:work_flow_id)
    |> foreign_key_constraint(:role_id)
  end
end
