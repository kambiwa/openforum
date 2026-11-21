defmodule Openforum.Context.Dashboard do
  @moduledoc """
  Read-only queries for the admin dashboard.
  """

  import Ecto.Query, warn: false

  alias Openforum.Repo
  alias Openforum.Context.Approvals
  alias Openforum.Schema.{ContentItem, MediaResource, WorkFlowStepAction}
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

    media = count(MediaResource)
    media_week = count(from media in MediaResource, where: media.inserted_at >= ago(7, "day"))

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
        label: "Media Resources",
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

  def analytics do
    status_counts =
      Repo.all(
        from item in ContentItem,
          group_by: item.status,
          select: {item.status, count(item.id)}
      )
      |> Map.new()

    statuses = [
      %{key: "published", label: "Published", color: "#1769AA"},
      %{key: "approved", label: "Approved", color: "#16A36A"},
      %{key: "pending_review", label: "In review", color: "#C9A227"},
      %{key: "document", label: "Drafts", color: "#8B9AA8"},
      %{key: "rejected", label: "Returned", color: "#D86969"}
    ]

    total =
      Enum.reduce(statuses, 0, fn status, sum -> sum + Map.get(status_counts, status.key, 0) end)

    pie =
      Enum.map_reduce(statuses, 0.0, fn status, offset ->
        count = Map.get(status_counts, status.key, 0)
        percent = if total == 0, do: 0.0, else: count / total * 100

        {Map.merge(status, %{
           count: count,
           percent: Float.round(percent, 2),
           offset: Float.round(offset, 2)
         }), offset + percent}
      end)
      |> elem(0)

    months = recent_months()
    first_month = List.first(months)
    earliest = DateTime.new!(first_month, ~T[00:00:00], "Etc/UTC")

    content_counts = monthly_counts(ContentItem, earliest)
    media_counts = monthly_counts(MediaResource, earliest)
    counts = merge_counts(content_counts, media_counts)

    max_count =
      Enum.reduce(months, 0, fn month, max -> max(max, Map.get(counts, month_key(month), 0)) end)

    bars =
      Enum.with_index(months)
      |> Enum.map(fn {month, index} ->
        count = Map.get(counts, month_key(month), 0)
        bar_height = if max_count == 0, do: 4, else: max(round(count / max_count * 112), 4)

        %{
          label: Calendar.strftime(month, "%b"),
          count: count,
          x: 23 + index * 88,
          y: 132 - bar_height,
          height: bar_height
        }
      end)

    %{status_pie: pie, total_content: total, monthly_activity: bars}
  end

  def system_health do
    database_status =
      try do
        case Repo.query("SELECT 1") do
          {:ok, _result} -> :healthy
          {:error, _reason} -> :degraded
        end
      rescue
        _ -> :degraded
      end

    static_dir = Path.join(:code.priv_dir(:openforum), "static")

    storage_status =
      case File.stat(static_dir) do
        {:ok, %File.Stat{type: :directory, access: access}}
        when access in [:write, :read_write] ->
          :healthy

        _ ->
          :degraded
      end

    started_at = :erlang.system_info(:start_time)

    uptime_seconds =
      max(
        System.monotonic_time(:second) - System.convert_time_unit(started_at, :native, :second),
        0
      )

    %{
      database: database_status,
      storage: storage_status,
      uptime_seconds: uptime_seconds,
      memory_mb: Float.round(:erlang.memory(:total) / 1_048_576, 1),
      checked_at: DateTime.utc_now()
    }
  end

  defp monthly_counts(schema, earliest) do
    Repo.all(
      from item in schema,
        where: item.inserted_at >= ^earliest,
        group_by: fragment("to_char(?, 'YYYY-MM')", item.inserted_at),
        select: {fragment("to_char(?, 'YYYY-MM')", item.inserted_at), count(item.id)}
    )
    |> Map.new()
  end

  defp merge_counts(left, right) do
    Map.merge(left, right, fn _month, left_count, right_count -> left_count + right_count end)
  end

  defp recent_months do
    current = Date.beginning_of_month(Date.utc_today())

    Enum.reduce(1..5, [current], fn _, [newest | _] = months ->
      previous = newest |> Date.add(-1) |> Date.beginning_of_month()
      [previous | months]
    end)
  end

  defp month_key(date), do: Calendar.strftime(date, "%Y-%m")

  defp count(queryable), do: Repo.aggregate(queryable, :count, :id)
end
