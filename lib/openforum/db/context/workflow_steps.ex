defmodule Openforum.Context.WorkFlowSteps do
  @moduledoc """
  Context for Workflows and their Steps.
  """

  alias Openforum.WorkFlow
  alias Openforum.WorkFlowStep
  alias OpenforumWeb.Schema.Role
  alias Openforum.Repo

  import Ecto.Query, warn: false

  @stage_rank %{draft: 0, reviewer: 1, approver: 2}

  # ── Workflows ────────────────────────────────────────────────────────

  @doc """
  Returns a paginated list of workflows with optional search + status filters.
  Expects the same shape that Pagination.create_table_params/2 produces.
  """
  def list_work_flows(params, filters \\ %{}) do
    WorkFlow
    |> filter_by_search(filters[:search_filter] || filters["search_filter"])
    |> filter_by_status(filters[:status_filter] || filters["status_filter"])
    |> order_by_from_params(params)
    |> paginate(params)
  end

  # Keep the old name working so the LiveView doesn't crash while you rename the call
  def list_steps(params, filters) when is_map(params) do
    list_work_flows(params, filters)
  end

  def get_work_flow!(id), do: Repo.get!(WorkFlow, id)

  def create_work_flow(attrs \\ %{}) do
    %WorkFlow{}
    |> WorkFlow.changeset(attrs)
    |> Repo.insert()
  end

  def update_work_flow(%WorkFlow{} = work_flow, attrs) do
    work_flow
    |> WorkFlow.changeset(attrs)
    |> Repo.update()
  end

  def delete_work_flow(%WorkFlow{} = work_flow) do
    Repo.delete(work_flow)
  end

  def change_work_flow(%WorkFlow{} = work_flow, attrs \\ %{}) do
    WorkFlow.changeset(work_flow, attrs)
  end

  @doc """
  Returns a map of work_flow_id => usage_count.
  Adjust the query to your real "content uses this workflow" association.
  """
  def usage_counts(ids) when is_list(ids) do
    # Example – replace with your real association
    # from(c in Content, where: c.work_flow_id in ^ids, group_by: c.work_flow_id, select: {c.work_flow_id, count(c.id)})
    # |> Repo.all()
    # |> Map.new()

    # Temporary safe fallback so the page doesn't crash
    Map.new(ids, &{&1, 0})
  end

  def step_count(%WorkFlow{id: id}) do
    WorkFlowStep
    |> where([s], s.work_flow_id == ^id)
    |> select([s], count(s.id))
    |> Repo.one()
  end

  def step_count(work_flow_id) when is_integer(work_flow_id) do
    WorkFlowStep
    |> where([s], s.work_flow_id == ^work_flow_id)
    |> select([s], count(s.id))
    |> Repo.one()
  end

  # ── Steps ────────────────────────────────────────────────────────────

  @doc """
  The fixed set of stage types, in workflow order.
  """
  def stage_types, do: [:draft, :reviewer, :approver]

  @doc """
  {label, value} pairs for a stage `<.input type="select">`.
  """
  def stage_options, do: [{"Draft", "draft"}, {"Reviewer", "reviewer"}, {"Approver", "approver"}]

  @doc """
  {label, id} pairs for the role `<.input type="select">` on a step form.
  """
  def list_roles_for_select do
    Role
    |> where([r], r.is_active == true)
    |> select([r], {r.name, r.id})
    |> order_by([r], asc: r.name)
    |> Repo.all()
  end

  @doc """
  Steps for a workflow, ordered by stage (Draft → Reviewer → Approver) and
  then by creation order within the same stage. `order_index` is computed
  and stored by `create_step/2` / `update_step/2` — there is no manual or
  draggable ordering anymore, so this is a plain column sort (and matches
  the `preload_order: [asc: :order_index]` already declared on
  `WorkFlow.work_flow_steps`).
  """
  def list_steps(work_flow_id) when is_integer(work_flow_id) or is_binary(work_flow_id) do
    WorkFlowStep
    |> where([s], s.work_flow_id == ^work_flow_id)
    |> order_by([s], asc: s.order_index)
    |> preload(:role)
    |> Repo.all()
  end

  def get_step!(id), do: WorkFlowStep |> Repo.get!(id) |> Repo.preload(:role)

  def create_step(work_flow_id, attrs) do
    stage = fetch_stage(attrs)

    attrs =
      attrs
      |> Map.put("work_flow_id", work_flow_id)
      |> Map.put("order_index", next_order_index(work_flow_id, stage))

    %WorkFlowStep{}
    |> WorkFlowStep.changeset(attrs)
    |> Repo.insert()
  end

  def update_step(%WorkFlowStep{} = step, attrs) do
    new_stage = fetch_stage(attrs)

    attrs =
      if new_stage && new_stage != step.stage_type do
        Map.put(attrs, "order_index", next_order_index(step.work_flow_id, new_stage))
      else
        attrs
      end

    step
    |> WorkFlowStep.changeset(attrs)
    |> Repo.update()
  end

  def delete_step(%WorkFlowStep{} = step) do
    Repo.delete(step)
  end

  def change_step(%WorkFlowStep{} = step, attrs \\ %{}) do
    WorkFlowStep.changeset(step, attrs)
  end

  # Reads "stage_type" (form params come in as strings) or :stage_type
  # (programmatic calls) out of attrs and normalizes it to an atom, without
  # blowing up on bad/missing input — validation of the real value still
  # happens via WorkFlowStep's Ecto.Enum cast in the changeset.
  defp fetch_stage(attrs) do
    case Map.get(attrs, "stage_type") || Map.get(attrs, :stage_type) do
      nil ->
        nil

      stage when stage in [:draft, :reviewer, :approver] ->
        stage

      stage when is_binary(stage) ->
        if stage in ~w(draft reviewer approver), do: String.to_existing_atom(stage), else: nil

      _ ->
        nil
    end
  end

  # Next order_index within a stage: stage_rank * 100_000 keeps stages in
  # separate bands (Draft: 0–99_999, Reviewer: 100_000–199_999, Approver:
  # 200_000+), and steps within a stage get sequential values in creation
  # order. This also satisfies the existing
  # unique_index(:work_flow_steps, [:work_flow_id, :order_index]).
  defp next_order_index(_work_flow_id, nil), do: 0

  defp next_order_index(work_flow_id, stage) do
    base = Map.fetch!(@stage_rank, stage) * 100_000

    max_in_stage =
      WorkFlowStep
      |> where([s], s.work_flow_id == ^work_flow_id and s.stage_type == ^stage)
      |> select([s], max(s.order_index))
      |> Repo.one()

    case max_in_stage do
      nil -> base
      val -> val + 1
    end
  end

  # ── Private helpers ──────────────────────────────────────────────────

  defp filter_by_search(query, search) when search in [nil, ""], do: query

  defp filter_by_search(query, search) do
    search = "%#{search}%"

    where(
      query,
      [w],
      ilike(w.name, ^search) or ilike(w.description, ^search)
    )
  end

  defp filter_by_status(query, status) when status in [nil, ""], do: query

  defp filter_by_status(query, status) do
    where(query, [w], w.status == ^status)
  end

  defp order_by_from_params(query, %{"order_by" => %{"sort_field" => field, "sort_direction" => dir}}) do
    direction = if dir == "asc", do: :asc, else: :desc

    case field do
      "name" -> order_by(query, [w], [{^direction, w.name}])
      "status" -> order_by(query, [w], [{^direction, w.status}])
      "inserted_at" -> order_by(query, [w], [{^direction, w.inserted_at}])
      _ -> order_by(query, [w], [{^direction, w.id}])
    end
  end

  defp order_by_from_params(query, _), do: order_by(query, [w], desc: w.id)

  # Very light pagination helper.
  # Replace the body with your real Pagination / Scrivener / Flop call
  # if you already have one that returns %{entries: ..., ...}.
  defp paginate(query, params) do
    page = String.to_integer(params["page"] || "1")
    page_size = String.to_integer(params["page_size"] || "10")

    %{
      entries: Repo.all(query |> limit(^page_size) |> offset(^((page - 1) * page_size))),
      page_number: page,
      page_size: page_size,
      total_entries: Repo.aggregate(query, :count, :id),
      total_pages: ceil(Repo.aggregate(query, :count, :id) / page_size)
    }
  end
end
