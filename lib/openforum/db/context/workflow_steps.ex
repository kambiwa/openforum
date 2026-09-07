defmodule Openforum.Context.WorkFlowSteps do
  @moduledoc """
  Context for Workflows and their Steps.
  """

  alias Openforum.WorkFlow
  alias Openforum.WorkFlowStep
  alias Openforum.Accounts.User
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
  Steps for a workflow, ordered by stage (Draft → Reviewer → Approver) and
  then by creation time within the same stage. Order is always computed —
  there is no manual/draggable ordering anymore.
  """
  def list_steps(work_flow_id) when is_integer(work_flow_id) or is_binary(work_flow_id) do
    WorkFlowStep
    |> where([s], s.work_flow_id == ^work_flow_id)
    |> order_by([s], asc: s.inserted_at)
    |> preload(:owners)
    |> Repo.all()
    |> Enum.sort_by(&Map.get(@stage_rank, &1.stage_type, 99))
  end

  def get_step!(id), do: WorkFlowStep |> Repo.get!(id) |> Repo.preload(:owners)

  @doc """
  {label, id} pairs for the owners multi-select.
  """
  def list_users_for_select do
    User
    |> select([u], {u.name, u.id})
    |> order_by([u], asc: u.name)
    |> Repo.all()
  end

  def create_step(work_flow_id, attrs, owner_ids \\ []) do
    %WorkFlowStep{}
    |> WorkFlowStep.changeset(Map.put(attrs, "work_flow_id", work_flow_id), list_users(owner_ids))
    |> Repo.insert()
  end

  def update_step(%WorkFlowStep{} = step, attrs, owner_ids \\ nil) do
    owners = owner_ids && list_users(owner_ids)

    step
    |> WorkFlowStep.changeset(attrs, owners)
    |> Repo.update()
  end

  def delete_step(%WorkFlowStep{} = step) do
    Repo.delete(step)
  end

  def change_step(%WorkFlowStep{} = step, attrs \\ %{}) do
    WorkFlowStep.changeset(step, attrs)
  end

  defp list_users(ids) do
    ids = Enum.reject(ids, &(&1 in [nil, ""]))
    User |> where([u], u.id in ^ids) |> Repo.all()
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
