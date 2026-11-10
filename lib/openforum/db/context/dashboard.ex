defmodule Openforum.Context.Dashboard do
  @moduledoc """
  Read-only queries for the admin dashboard.
  """

  import Ecto.Query, warn: false

  alias Openforum.Repo
  alias Openforum.Context.Approvals
  alias Openforum.Schema.{ContentItem, ContentAttachment, WorkFlowStepAction}
  alias Openforum.Accounts.User

  @doc """
  Headline numbers for the stat cards. `user` is the signed-in user
  (with roles loaded), used for the personal pending-approval count.
  """
  def stats(user) do
    total = count(ContentItem)
    total_week = count(from c in ContentItem, where: c.inserted_at >= ago(7, "day"))

    published = count(from c in ContentItem, where: c.status == "published")

    published_week =
      count(
        from c in ContentItem,
          where: c.status == "published" and c.published_at >= ago(7, "day")
      )

    media = count(ContentAttachment)
    media_week = count(from a in ContentAttachment, where: a.inserted_at >= ago(7, "day"))

    pending = Approvals.list_pending_for_reviewer(user, %{"page_size" => "1"}).total_entries

    drafts = count(from c in ContentItem, where: c.status == "document")

    [
      %{
        label: "Total Content",
        value: total,
        icon: "hero-document-text",
        change: "+#{total_week} this week",
        tone: :blue
      },
      %{
        label: "Awaiting Your Review",
        value: pending,
        icon: "hero-clock",
        change: if(pending == 0, do: "All caught up", else: "Needs your action"),
        tone: :amber
      },
      %{
        label: "Published",
        value: published,
        icon: "hero-globe-alt",
        change: "+#{published_week} this week",
        tone: :green
      },
      %{
        label: "Media Items",
        value: media,
        icon: "hero-photo",
        change: "+#{media_week} this week · #{drafts} drafts in progress",
        tone: :slate
      }
    ]
  end

  @doc "The newest documents waiting on this user, with category, step and author loaded."
  def pending_for(user, limit \\ 5) do
    Approvals.list_pending_for_reviewer(user, %{"page_size" => to_string(limit)}).entries
    |> Repo.preload(:author)
  end

  @doc "Latest workflow actions (submit / approve / reject) across all documents."
  def recent_activity(limit \\ 6) do
    Repo.all(
      from a in WorkFlowStepAction,
        join: c in ContentItem,
        on: c.id == a.content_item_id,
        join: u in User,
        on: u.id == a.actor_id,
        order_by: [desc: a.inserted_at, desc: a.id],
        limit: ^limit,
        select: %{
          action: a.action,
          title: c.title,
          first_name: u.first_name,
          last_name: u.last_name,
          at: a.inserted_at
        }
    )
  end

  defp count(queryable), do: Repo.aggregate(queryable, :count, :id)
end
