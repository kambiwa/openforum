defmodule Openforum.Context.Drafts do
  @moduledoc """
  "My Drafts" — content_items still in the :draft stage, owned by the
  current user.
  """

  import Ecto.Query, warn: false

  alias Openforum.Schema.{ContentItem, ContentCategory, WorkFlowStepAction}
  alias Openforum.Context.WorkFlowSteps
  alias Openforum.Schema.ContentAttachment
  alias Openforum.Repo

  def list_drafts(current_user, params, filters \\ %{}) do
    ContentItem
    |> where([c], c.author_id == ^current_user.id and c.status == "draft")
    |> filter_by_search(filters[:search_filter] || filters["search_filter"])
    |> filter_by_category(filters[:category_filter] || filters["category_filter"])
    |> order_by_from_params(params)
    |> paginate(params)
  end

  def get_draft!(current_user, id) do
    ContentItem
    |> where([c], c.author_id == ^current_user.id and c.id == ^id)
    |> preload([:category, :work_flow, :current_step])
    |> Repo.one!()
  end

  def list_categories_for_select do
    ContentCategory
    |> where([c], c.is_active == true)
    |> select([c], {c.name, c.id})
    |> order_by([c], asc: c.order_index)
    |> Repo.all()
  end


  def get_draft!(current_user, id) do
    ContentItem
    |> where([c], c.author_id == ^current_user.id and c.id == ^id)
    |> preload([:category, :work_flow, :current_step, :content_attachments])
    |> Repo.one!()
  end

  def create_attachment(%ContentItem{} = draft, attrs) do
    %ContentAttachment{}
    |> ContentAttachment.changeset(Map.put(attrs, "content_item_id", draft.id))
    |> Repo.insert()
  end

def delete_attachment(%ContentAttachment{} = attachment), do: Repo.delete(attachment)

def get_attachment!(id), do: Repo.get!(ContentAttachment, id)

  def change_draft(%ContentItem{id: nil} = draft, attrs \\ %{}), do: ContentItem.create_changeset(draft, attrs)

  def change_draft(%ContentItem{} = draft, attrs), do: ContentItem.update_changeset(draft, attrs)

  @doc """
  Resolves category -> default_work_flow_id -> first :draft-stage step,
  and blocks creation with a changeset error if either is missing.
  """
  def create_draft(current_user, attrs) do
    changeset = ContentItem.create_changeset(%ContentItem{}, attrs)
    category_id = Ecto.Changeset.get_field(changeset, :category_id)

    with {:ok, category} <- fetch_category(category_id),
         {:ok, work_flow_id} <- fetch_default_work_flow(category),
         {:ok, step} <- fetch_first_step_for_stage(work_flow_id, :draft) do
      changeset
      |> Ecto.Changeset.put_change(:author_id, current_user.id)
      |> Ecto.Changeset.put_change(:workflow_id, work_flow_id)
      |> Ecto.Changeset.put_change(:current_step_id, step.id)
      |> Ecto.Changeset.put_change(:status, "draft")
      |> Repo.insert()
    else
      {:error, :no_category} ->
        {:error, Ecto.Changeset.add_error(changeset, :category_id, "is invalid")}

      {:error, :no_work_flow} ->
        {:error,
         Ecto.Changeset.add_error(
           changeset,
           :category_id,
           "has no workflow configured — ask an admin to set one up"
         )}

      {:error, :no_step} ->
        {:error,
         Ecto.Changeset.add_error(
           changeset,
           :category_id,
           "workflow has no draft step configured — ask an admin to fix it"
         )}
    end
  end

  def update_draft(%ContentItem{} = draft, attrs) do
    draft |> ContentItem.update_changeset(attrs) |> Repo.update()
  end

  def delete_draft(%ContentItem{} = draft), do: Repo.delete(draft)

  @doc """
  Logs the submit action, advances current_step_id to the first
  :reviewer step, flips status to "in_review". A note is required
  (work_flow_step_actions.comments is NOT NULL).
  """
  def submit_draft(%ContentItem{} = draft, note, current_user) do
    note = String.trim(note || "")

    with true <- note != "" || {:error, :note_required},
         {:ok, reviewer_step} <- fetch_first_step_for_stage(draft.workflow_id, :reviewer) do
      Repo.transaction(fn ->
        {:ok, _action} =
          %WorkFlowStepAction{}
          |> WorkFlowStepAction.changeset(%{
            content_item_id: draft.id,
            work_flow_step_id: draft.current_step_id,
            actor_id: current_user.id,
            action: "submit",
            comments: note
          })
          |> Repo.insert()

        {:ok, updated} =
          draft
          |> Ecto.Changeset.change(%{current_step_id: reviewer_step.id, status: "in_review"})
          |> Repo.update()

        updated
      end)
    else
      {:error, :note_required} -> {:error, :note_required}
      {:error, :no_step} -> {:error, :no_reviewer_step}
    end
  end

  # ── Private ──────────────────────────────────────────────────────────

  defp fetch_category(nil), do: {:error, :no_category}
  defp fetch_category(id) do
    case Repo.get(ContentCategory, id) do
      nil -> {:error, :no_category}
      category -> {:ok, category}
    end
  end

  defp fetch_default_work_flow(%ContentCategory{default_work_flow_id: nil}), do: {:error, :no_work_flow}
  defp fetch_default_work_flow(%ContentCategory{default_work_flow_id: id}), do: {:ok, id}

  defp fetch_first_step_for_stage(work_flow_id, stage) do
    case WorkFlowSteps.first_step_for_stage(work_flow_id, stage) do
      nil -> {:error, :no_step}
      step -> {:ok, step}
    end
  end

  defp filter_by_search(query, s) when s in [nil, ""], do: query
  defp filter_by_search(query, s) do
    s = "%#{s}%"
    where(query, [c], ilike(c.title, ^s) or ilike(c.summary, ^s))
  end

  defp filter_by_category(query, c) when c in [nil, ""], do: query
  defp filter_by_category(query, c), do: where(query, [c2], c2.category_id == ^c)

  defp order_by_from_params(query, %{"order_by" => %{"sort_field" => field, "sort_direction" => dir}}) do
    direction = if dir == "asc", do: :asc, else: :desc

    case field do
      "title" -> order_by(query, [c], [{^direction, c.title}])
      "inserted_at" -> order_by(query, [c], [{^direction, c.inserted_at}])
      _ -> order_by(query, [c], [{^direction, c.id}])
    end
  end

  defp order_by_from_params(query, _), do: order_by(query, [c], desc: c.id)

  defp paginate(query, params) do
    page = String.to_integer(params["page"] || "1")
    page_size = String.to_integer(params["page_size"] || "10")

    %{
      entries:
        Repo.all(query |> preload(:category) |> limit(^page_size) |> offset(^((page - 1) * page_size))),
      page_number: page,
      page_size: page_size,
      total_entries: Repo.aggregate(query, :count, :id),
      total_pages: ceil(Repo.aggregate(query, :count, :id) / page_size)
    }
  end
end
