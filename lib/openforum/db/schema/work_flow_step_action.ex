defmodule Openforum.WorkFlowStepAction do
  use Ecto.Schema
  import Ecto.Changeset

  @actions ~w(approve mark_as_reviewed reject)

  schema "work_flow_step_actions" do
    belongs_to :content_item, Openforum.ContentItem
    belongs_to :work_flow_step, Openforum.WorkFlowStep
    belongs_to :actor, Openforum.Accounts.User
    belongs_to :acted_as_role, Openforum.Role

    field :action, :string
    field :comments, :string

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(action, attrs) do
    action
    |> cast(attrs, [
      :content_item_id,
      :work_flow_step_id,
      :actor_id,
      :acted_as_role_id,
      :action,
      :comments
    ])
    |> validate_required([:content_item_id, :work_flow_step_id, :action, :comments])
    |> validate_inclusion(:action, @actions)
    |> validate_length(:comments, min: 1)
    |> foreign_key_constraint(:content_item_id)
    |> foreign_key_constraint(:work_flow_step_id)
    |> foreign_key_constraint(:actor_id)
    |> foreign_key_constraint(:acted_as_role_id)
  end
end
