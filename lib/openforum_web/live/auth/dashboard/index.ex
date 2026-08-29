defmodule OpenforumWeb.Auth.Dashboard.Index do
  use OpenforumWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:current_scope, "")
      |> assign(:mobile_menu_open, false)
      |> assign(:page_title, "Dashboard")
      |> assign(:current_page, :dashboard)
      |> assign(:stats, stats())
      |> assign(:pending_approvals, pending_approvals())
      |> assign(:recent_activity, recent_activity())
      |> assign(:quick_actions, quick_actions())

    {:ok, socket}
  end

  # TODO: replace with real queries once the content/approval schemas are wired up
  # (Content.count_by_status/0, Content.pending_for_user/1, Activity.recent/1, etc.)
  defp stats do
    [
      %{label: "Total Content", value: "128", icon: "hero-document-text", change: "+6 this week"},
      %{label: "Pending Approval", value: "9", icon: "hero-clock", change: "3 due today"},
      %{label: "Published", value: "94", icon: "hero-globe-alt", change: "+2 this week"},
      %{label: "Media Items", value: "37", icon: "hero-photo", change: "+1 this week"}
    ]
  end

  defp pending_approvals do
    [
      %{
        title: "Understanding Grace and Redemption",
        category: "Doctrine",
        level: "District Rector Area",
        submitted_by: "Admin Dev",
        submitted_at: "2 days ago"
      },
      %{
        title: "Catechism Study — Session 4",
        category: "Catechism",
        level: "Apostle Area",
        submitted_by: "Sarah Mwansa",
        submitted_at: "3 days ago"
      },
      %{
        title: "Q&A: On Baptism of the Dead",
        category: "Questions & Answers",
        level: "Congregation",
        submitted_by: "James Banda",
        submitted_at: "5 hours ago"
      },
      %{
        title: "The Ministry Today",
        category: "Media",
        level: "Lead Apostle Area",
        submitted_by: "Grace Phiri",
        submitted_at: "1 day ago"
      }
    ]
  end

  defp recent_activity do
    [
      %{
        message: "\"The Holy Bible\" was published",
        actor: "District Apostle Area",
        timestamp: "1 hour ago",
        icon: "hero-check-circle"
      },
      %{
        message: "New draft created: \"Living the Ten Commandments\"",
        actor: "Admin Dev",
        timestamp: "4 hours ago",
        icon: "hero-pencil-square"
      },
      %{
        message: "Media uploaded to Doctrine category",
        actor: "Grace Phiri",
        timestamp: "Yesterday",
        icon: "hero-photo"
      },
      %{
        message: "\"Understanding Our Faith\" returned for revision",
        actor: "Apostle Area",
        timestamp: "2 days ago",
        icon: "hero-arrow-uturn-left"
      }
    ]
  end

  defp quick_actions do
    [
      %{label: "New Bible Content", icon: "hero-book-open", href: "/admin/bible/new"},
      %{label: "New Doctrine Article", icon: "hero-academic-cap", href: "/admin/doctrine/new"},
      %{label: "Upload Media", icon: "hero-photo", href: "/admin/media/new"},
      %{label: "Review Approval Queue", icon: "hero-clock", href: "/admin/approval-queue"}
    ]
  end
end
