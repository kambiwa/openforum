defmodule Openforum.WorkFlow do
  use Ecto.Schema
  import Ecto.Changeset

  schema "work_flows" do
    field :name, :string
    field :status, :string, default: "active"
    field :description, :string

    has_many :work_flow_steps, Openforum.WorkFlowStep,
      preload_order: [asc: :order_index],
      on_delete: :delete_all

    timestamps(type: :utc_datetime)
  end

  def changeset(work_flow, attrs) do
    work_flow
    |> cast(attrs, [:name, :status, :description])
    |> validate_required([:name, :status])
    |> validate_length(:name, min: 1, max: 160)
    |> validate_inclusion(:status, ["active", "inactive", "draft"])
    |> unique_constraint(:name)
  end

  def step_count(%__MODULE__{work_flow_steps: steps}) when is_list(steps), do: length(steps)
  def step_count(_), do: 0
end
