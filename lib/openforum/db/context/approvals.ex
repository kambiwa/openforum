defmodule Openforum.Context.Approvals do
  import Ecto.Query, warn: false
  alias Openforum.Schema.{WorkFlowStep, WorkFlowStepAction}
  alias Openforum.Context.WorkFlowSteps
  alias Openforum.Schema.ContentItem
  alias Openforum.Repo


def get_for_review!(id) do
  ContentItem |> preload([:category, :current_step]) |> Repo.get!(id)
end

def approve(%ContentItem{} = doc, note, user) do
  with :ok <- require_note(note),
       :ok <- authorize(doc, user) do
    attrs =
      case next_step(doc.current_step) do
        nil -> %{status: "approved"}
        step -> %{current_step_id: step.id}
      end

    decide(doc, user, "approve", note, attrs)
  end
end

def reject(%ContentItem{} = doc, note, user) do
  with :ok <- require_note(note),
       :ok <- authorize(doc, user),
       %{} = back <- WorkFlowSteps.first_step_for_stage(doc.workflow_id, :document) do
    decide(doc, user, "reject", note, %{status: "rejected", current_step_id: back.id})
  else
    nil -> {:error, :no_document_step}
    error -> error
  end
end

defp decide(doc, user, action, note, attrs) do
  Repo.transaction(fn ->
    %WorkFlowStepAction{}
    |> WorkFlowStepAction.changeset(%{
      content_item_id: doc.id,
      work_flow_step_id: doc.current_step_id,
      actor_id: user.id,
      action: action,
      comments: String.trim(note)
    })
    |> Repo.insert!()

    doc |> Ecto.Changeset.change(attrs) |> Repo.update!()
  end)
end

defp require_note(note) when is_binary(note) do
  if String.trim(note) == "", do: {:error, :note_required}, else: :ok
end

defp require_note(_), do: {:error, :note_required}

defp authorize(%ContentItem{status: "pending_review", current_step: step}, user) do
  if Enum.any?(user.roles, &(&1.id == step.role_id)), do: :ok, else: {:error, :not_authorized}
end

defp authorize(_, _), do: {:error, :not_pending}

defp next_step(%WorkFlowStep{} = step) do
  WorkFlowStep
  |> where([s], s.work_flow_id == ^step.work_flow_id and s.order_index > ^step.order_index)
  |> order_by([s], asc: s.order_index)
  |> limit(1)
  |> Repo.one()
end

  def list_pending_for_reviewer(user, params) do
    role_ids = Enum.map(user.roles, & &1.id)

    ContentItem
    |> join(:inner, [c], s in assoc(c, :current_step))
    |> where([c, s], c.status == "pending_review" and s.role_id in ^role_ids)
    |> where([c], c.author_id != ^user.id)
    |> order_by([c], desc: c.id)
    |> paginate(params)
  end


  defp paginate(query, params) do
    page = String.to_integer(params["page"] || "1")
    page_size = String.to_integer(params["page_size"] || "10")
    total = Repo.aggregate(query, :count, :id)

    %{
      entries:
        query
        |> preload([:category, :current_step])
        |> limit(^page_size)
        |> offset(^((page - 1) * page_size))
        |> Repo.all(),
      page_number: page,
      page_size: page_size,
      total_entries: total,
      total_pages: max(ceil(total / page_size), 1)
    }
  end
end
