defmodule Openforum.Context.Publications do
  @moduledoc "Queries and publication actions for approved content."

  import Ecto.Query, warn: false

  alias Openforum.Repo
  alias Openforum.Schema.{ContentCategory, ContentItem, MediaResource}

  @visible_statuses ~w(approved published)
  @public_statuses ~w(published)

  def list_public_categories do
    categories_with_content =
      from(item in ContentItem,
        where: item.status in ^@public_statuses,
        select: item.category_id
      )

    ContentCategory
    |> where([category], category.is_active and category.id in subquery(categories_with_content))
    |> order_by([category], asc: category.order_index, asc: category.name)
    |> Repo.all()
  end

  def list_public_content(category_id \\ nil) do
    ContentItem
    |> where([item], item.status in ^@public_statuses)
    |> maybe_filter_category(category_id)
    |> order_by([item], desc: item.updated_at, desc: item.id)
    |> preload([:category, :author])
    |> Repo.all()
  end

  def list_public_media do
    MediaResource
    |> where([resource], resource.status == "published")
    |> order_by([resource], desc: resource.inserted_at, desc: resource.id)
    |> preload(:category)
    |> Repo.all()
  end

  def get_published_content(id) do
    case Integer.parse(to_string(id)) do
      {item_id, ""} ->
        ContentItem
        |> where([item], item.id == ^item_id and item.status == "published")
        |> preload([:category, :author])
        |> Repo.one()

      _ ->
        nil
    end
  end

  def list_admin_content(params, filters \\ %{}) do
    page = OpenforumWeb.Pagination.param_value(params, "page", 1)
    page_size = OpenforumWeb.Pagination.param_value(params, "page_size", 10)

    search =
      filters[:search_filter] || filters["search_filter"] ||
        get_in(params, ["filter", "isearch"]) || ""

    status = filters[:status_filter] || filters["status_filter"] || ""

    query =
      ContentItem
      |> where([item], item.status in ^@visible_statuses)
      |> apply_status(status)
      |> apply_search(search)
      |> order_by([item],
        desc: fragment("CASE WHEN ? = 'approved' THEN 0 ELSE 1 END", item.status)
      )
      |> order_by([item], desc: item.updated_at, desc: item.id)

    total_entries = Repo.aggregate(query, :count, :id)
    page = max(page, 1)
    page_size = min(max(page_size, 1), 100)

    entries =
      query
      |> preload([:category, :author])
      |> limit(^page_size)
      |> offset(^((page - 1) * page_size))
      |> Repo.all()

    %{
      entries: entries,
      page_number: page,
      page_size: page_size,
      total_entries: total_entries,
      total_pages: max(ceil(total_entries / page_size), 1)
    }
  end

  def publish_approved_content(id) do
    published_at = DateTime.utc_now(:second)

    {updated_count, _} =
      Repo.update_all(
        from(item in ContentItem, where: item.id == ^id and item.status == "approved"),
        set: [status: "published", published_at: published_at, updated_at: published_at]
      )

    case updated_count do
      1 -> {:ok, Repo.get!(ContentItem, id)}
      0 -> {:error, :not_pending_publication}
    end
  end

  defp apply_status(query, status) when status in [nil, ""], do: query
  defp apply_status(query, status), do: where(query, [item], item.status == ^status)

  defp apply_search(query, search) when search in [nil, ""], do: query

  defp apply_search(query, search) do
    pattern = "%#{search}%"

    where(query, [item], ilike(item.title, ^pattern) or ilike(item.summary, ^pattern))
  end

  defp maybe_filter_category(query, category_id) when category_id in [nil, ""], do: query

  defp maybe_filter_category(query, category_id) do
    case Integer.parse(to_string(category_id)) do
      {id, ""} -> where(query, [item], item.category_id == ^id)
      _ -> where(query, [item], item.category_id == -1)
    end
  end
end
