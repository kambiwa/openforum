defmodule OpenForum.Context.AreaLeads do
  alias OpenForumWeb.Schema.AreaLead
  alias OpenForumWeb.Repo

  import Ecto.Query, warn: false

  # ── Paginated list (used by the LiveView index) ──────────────────────

  def list_area_leads(table_params \\ %{}, filters \\ %{}) do
    page = OpenForum.Pagination.param_value(table_params, "page", 1)
    page_size = OpenForum.Pagination.param_value(table_params, "page_size", 10)
    order_by = table_params["order_by"] || %{"sort_field" => "id", "sort_direction" => "desc"}
    search = get_in(table_params, ["filter", "isearch"]) || ""
    status = filters[:status_filter] || filters["status_filter"] || ""

    AreaLead
    |> apply_search(search)
    |> apply_status(status)
    |> apply_order(order_by)
    |> Repo.paginate(page: page, page_size: page_size)
  end

  # ── Standard CRUD ────────────────────────────────────────────────────

  def get_area_lead!(id), do: Repo.get!(AreaLead, id)

  def create_area_lead(attrs \\ %{}) do
    %AreaLead{}
    |> AreaLead.changeset(attrs)
    |> Repo.insert()
  end

  def update_area_lead(%AreaLead{} = area_lead, attrs) do
    area_lead
    |> AreaLead.changeset(attrs)
    |> Repo.update()
  end

  def delete_area_lead(%AreaLead{} = area_lead) do
    Repo.delete(area_lead)
  end

  def change_area_lead(%AreaLead{} = area_lead, attrs \\ %{}) do
    AreaLead.changeset(area_lead, attrs)
  end

  # ── Private query helpers ────────────────────────────────────────────

  defp apply_search(query, ""), do: query
  defp apply_search(query, nil), do: query

  defp apply_search(query, search) do
    term = "%#{search}%"
    where(query, [f], ilike(f.name, ^term) or ilike(f.description, ^term))
  end

  defp apply_status(query, ""), do: query
  defp apply_status(query, nil), do: query

  defp apply_status(query, status) do
    where(query, [f], f.status == ^status)
  end

  defp apply_order(query, %{"sort_field" => field, "sort_direction" => direction}) do
    order = if direction == "asc", do: :asc, else: :desc

    case field do
      "name" -> order_by(query, [f], [{^order, f.name}])
      "status" -> order_by(query, [f], [{^order, f.status}])
      "inserted_at" -> order_by(query, [f], [{^order, f.inserted_at}])
      _ -> order_by(query, [f], [{^order, f.id}])
    end
  end

  defp apply_order(query, _), do: order_by(query, [f], desc: f.id)
end
