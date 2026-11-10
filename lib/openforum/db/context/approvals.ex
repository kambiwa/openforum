defmodule Openforum.Context.Approvals do
  import Ecto.Query, warn: false
  alias Openforum.Repo
  alias Openforum.Schema.ContentItem

  def list_pending_for_reviewer(user, params) do
    role_ids = Enum.map(user.roles, & &1.id)

    ContentItem
    |> join(:inner, [c], s in assoc(c, :current_step))
    |> where([c, s], c.status == "pending_review" and s.approver_role_id in ^role_ids)
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
