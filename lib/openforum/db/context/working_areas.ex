defmodule Openforum.Context.WorkingAreas do
  alias OpenforumWeb.Schema.WorkingArea
  alias Openforum.Repo

  import Ecto.Query, warn: false

  # ── Paginated list (used by the LiveView index) ──────────────────────

  def list_working_areas(table_params \\ %{}, filters \\ %{}) do
    page = OpenforumWeb.Pagination.param_value(table_params, "page", 1)
    page_size = OpenforumWeb.Pagination.param_value(table_params, "page_size", 10)
    order_by = table_params["order_by"] || %{"sort_field" => "id", "sort_direction" => "desc"}
    search = get_in(table_params, ["filter", "isearch"]) || ""
    status = filters[:status_filter] || filters["status_filter"] || ""

    WorkingArea
    |> apply_search(search)
    |> apply_status(status)
    |> apply_order(order_by)
    |> Repo.paginate(page: page, page_size: page_size)
  end
  # ── Standard CRUD ────────────────────────────────────────────────────

  def get_working_area!(id), do: Repo.get!(WorkingArea, id)

  def create_working_area(attrs \\ %{}) do
    %WorkingArea{}
    |> WorkingArea.changeset(attrs)
    |> Repo.insert()
  end

  def update_working_area(%WorkingArea{} = working_area, attrs) do
    working_area
    |> WorkingArea.changeset(attrs)
    |> Repo.update()
  end

  def delete_working_area(%WorkingArea{} = working_area) do
    Repo.delete(working_area)
  end

  def change_working_area(%WorkingArea{} = working_area, attrs \\ %{}) do
    WorkingArea.changeset(working_area, attrs)
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
