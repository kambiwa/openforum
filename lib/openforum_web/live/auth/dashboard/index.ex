defmodule OpenforumWeb.Auth.Dashboard.Index do
  use OpenforumWeb, :live_view

  alias Openforum.Context.Dashboard

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user

    socket =
      socket
      |> assign(:mobile_menu_open, false)
      |> assign(:page_title, "Dashboard")
      |> assign(:current_page, :dashboard)
      |> assign(:stats, Dashboard.stats(user))
      |> assign(:pending_approvals, Dashboard.pending_for(user))
      |> assign(:recent_activity, Dashboard.recent_activity())
      |> assign(:quick_actions, quick_actions())

    {:ok, socket}
  end

  # NOTE: make sure these hrefs match your router.
  defp quick_actions do
    [
      %{label: "New Document", icon: "hero-pencil-square", href: "/admin/documents"},
      %{label: "Review Approval Queue", icon: "hero-clock", href: "/admin/approval-queue"},
      %{label: "Published Content", icon: "hero-globe-alt", href: "/admin/published"},
      %{label: "Upload Media", icon: "hero-photo", href: "/admin/media/new"}
    ]
  end

  # ── View helpers ────────────────────────────────────────────────────

  defp full_name(nil), do: "Unknown"

  defp full_name(user) do
    String.trim("#{user.first_name} #{user.last_name}")
  end

  defp tone_classes(:blue), do: "bg-[#EAF3F8] text-[#1769AA]"
  defp tone_classes(:amber), do: "bg-amber-50 text-amber-600"
  defp tone_classes(:green), do: "bg-emerald-50 text-emerald-600"
  defp tone_classes(_), do: "bg-slate-100 text-slate-600"

  defp activity_icon("approve"), do: "hero-check-circle"
  defp activity_icon("reject"), do: "hero-arrow-uturn-left"
  defp activity_icon(_), do: "hero-paper-airplane"

  defp activity_icon_classes("approve"), do: "bg-emerald-50 text-emerald-600"
  defp activity_icon_classes("reject"), do: "bg-red-50 text-red-600"
  defp activity_icon_classes(_), do: "bg-[#EAF3F8] text-[#1769AA]"

  defp activity_verb("approve"), do: "approved"
  defp activity_verb("reject"), do: "returned"
  defp activity_verb("submit"), do: "submitted"
  defp activity_verb(other), do: to_string(other)

  defp time_ago(nil), do: ""
  defp time_ago(%DateTime{} = dt), do: dt |> DateTime.to_naive() |> time_ago()

  defp time_ago(%NaiveDateTime{} = ndt) do
    secs = NaiveDateTime.diff(NaiveDateTime.utc_now(), ndt)

    cond do
      secs < 60 -> "just now"
      secs < 3_600 -> "#{div(secs, 60)} min ago"
      secs < 86_400 -> "#{div(secs, 3_600)} hr ago"
      secs < 172_800 -> "Yesterday"
      true -> "#{div(secs, 86_400)} days ago"
    end
  end
end
