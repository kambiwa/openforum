defmodule OpenforumWeb.Unauth.Landing.Index do
  use OpenforumWeb, :live_view

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:current_scope, "")
      |> assign(:mobile_menu_open, false)
      |> assign(:page_title, "OpenForum — New Apostolic Church Knowledge Platform")
      |> assign(:knowledge_categories, knowledge_categories())
      |> assign(:featured_topics, featured_topics())
      |> assign(:approval_steps, approval_steps())
      |> assign(:media_resources, media_resources())
      |> assign(:access_benefits, access_benefits())
      |> assign(:contributor_steps, contributor_steps())

    {:ok, socket}
  end

  def handle_event("toggle_mobile_menu", _params, socket) do
    {:noreply, assign(socket, :mobile_menu_open, !socket.assigns.mobile_menu_open)}
  end

  defp knowledge_categories do
    [
      %{
        icon: "hero-book-open",
        title: "Bible",
        description:
          "Read and explore the Holy Scriptures through a structured and accessible learning experience."
      },
      %{
        icon: "hero-academic-cap",
        title: "Doctrine",
        description:
          "Discover the teachings, beliefs and doctrinal foundations of the New Apostolic Church."
      },
      %{
        icon: "hero-bookmark",
        title: "Catechism",
        description:
          "Study the New Apostolic Church Catechism and deepen your understanding of faith."
      },
      %{
        icon: "hero-question-mark-circle",
        title: "Questions & Answers",
        description:
          "Find clear answers to important questions about faith, doctrine and church life."
      },
      %{
        icon: "hero-play-circle",
        title: "Media",
        description:
          "Learn through approved videos, audio teachings, presentations and other media."
      }
    ]
  end

  defp featured_topics do
    [
      %{
        label: "Faith Foundations",
        title: "Understanding Our Faith",
        description: "A guided introduction to the foundations of New Apostolic faith.",
        duration: "12 min read",
        image: "understanding-our-faith"
      },
      %{
        label: "Scripture",
        title: "The Holy Bible",
        description: "Explore Scripture and discover its relevance to faith and everyday life.",
        duration: "18 min read",
        image: "the-holy-bible"
      },
      %{
        label: "Catechism",
        title: "Catechism Study",
        description: "Study key teachings and principles of the New Apostolic Church.",
        duration: "15 min read",
        image: "catechism-study"
      }
    ]
  end

  defp approval_steps do
    [
      %{icon: "hero-user-group", title: "Congregation"},
      %{icon: "hero-building-office-2", title: "District Rector Area"},
      %{icon: "hero-flag", title: "Apostle Area"},
      %{icon: "hero-globe-alt", title: "Lead Apostle Area"},
      %{icon: "hero-shield-check", title: "District Apostle Area"}
    ]
  end

  defp media_resources do
    [
      %{
        title: "The Nature of Grace",
        category: "Audio Teaching",
        duration: "24 min"
      },
      %{
        title: "Living the Ten Commandments",
        category: "Audio Resource",
        duration: "31 min"
      },
      %{
        title: "District Apostle Area Address",
        category: "Video",
        duration: "42 min"
      }
    ]
  end

  defp access_benefits do
    [
      %{
        icon: "hero-globe-alt",
        title: "Public Access",
        description: "Explore core resources with no account required."
      },
      %{
        icon: "hero-shield-check",
        title: "Trusted Resources",
        description: "Every resource follows the approved review workflow."
      },
      %{
        icon: "hero-device-phone-mobile",
        title: "Learn Anywhere",
        description: "Access OpenForum on any device, at your own pace."
      }
    ]
  end

  defp contributor_steps do
    [
      "Create Content",
      "Add Supporting Media",
      "Submit for Review",
      "Approval Workflow",
      "Publish to OpenForum"
    ]
  end
end
