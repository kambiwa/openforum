defmodule OpenforumWeb.Unauth.Learn.Index do
  use OpenforumWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:mobile_menu_open, false)
      |> assign(:page_title, "Start Learning — OpenForum")
      |> assign(:categories, categories())
      |> assign(:active_category, "all")
      |> assign(:learning_paths, learning_paths())
      |> assign(:visible_paths, learning_paths())
      |> assign(:how_it_works, how_it_works())

    {:ok, socket}
  end

  @impl true
  def handle_event("toggle_mobile_menu", _params, socket) do
    {:noreply, assign(socket, :mobile_menu_open, !socket.assigns.mobile_menu_open)}
  end

  def handle_event("filter_category", %{"category" => category}, socket) do
    valid? = category == "all" or Enum.any?(categories(), &(&1.id == category))
    category = if valid?, do: category, else: "all"

    {:noreply,
     socket
     |> assign(:active_category, category)
     |> assign(:visible_paths, filter_paths(socket.assigns.learning_paths, category))}
  end

  defp filter_paths(paths, "all"), do: paths
  defp filter_paths(paths, category), do: Enum.filter(paths, &(&1.category == category))

  defp categories do
    [
      %{id: "faith", label: "Faith Foundations"},
      %{id: "bible", label: "Bible"},
      %{id: "doctrine", label: "Doctrine"},
      %{id: "catechism", label: "Catechism"},
      %{id: "qa", label: "Questions & Answers"}
    ]
  end

  defp learning_paths do
    [
      %{
        category: "faith",
        icon: "hero-sparkles",
        level: "Beginner",
        title: "Understanding Our Faith",
        description: "A guided introduction to the foundations of New Apostolic faith.",
        lessons: 6,
        duration: "1 hr 10 min"
      },
      %{
        category: "bible",
        icon: "hero-book-open",
        level: "Beginner",
        title: "The Holy Bible",
        description: "Explore Scripture and discover its relevance to faith and everyday life.",
        lessons: 8,
        duration: "2 hr"
      },
      %{
        category: "bible",
        icon: "hero-book-open",
        level: "Intermediate",
        title: "Reading Scripture Together",
        description: "Learn how to read, reflect on and discuss passages with others.",
        lessons: 5,
        duration: "1 hr 20 min"
      },
      %{
        category: "doctrine",
        icon: "hero-academic-cap",
        level: "Intermediate",
        title: "Foundations of Doctrine",
        description: "Discover the teachings and beliefs that shape the New Apostolic Church.",
        lessons: 7,
        duration: "1 hr 45 min"
      },
      %{
        category: "catechism",
        icon: "hero-bookmark",
        level: "Intermediate",
        title: "Catechism Study",
        description: "Study key teachings and principles of the New Apostolic Church.",
        lessons: 10,
        duration: "2 hr 30 min"
      },
      %{
        category: "qa",
        icon: "hero-question-mark-circle",
        level: "All levels",
        title: "Common Questions About Faith",
        description: "Clear answers to frequently asked questions about faith and church life.",
        lessons: 12,
        duration: "1 hr 30 min"
      }
    ]
  end

  defp how_it_works do
    [
      %{
        title: "Choose a path",
        description: "Pick a topic that matches what you want to understand."
      },
      %{
        title: "Learn step by step",
        description: "Move through short lessons of text, audio and video."
      },
      %{
        title: "Go deeper",
        description: "Follow links into Bible, Doctrine, Catechism and Q&A."
      }
    ]
  end

  def category_label(id) do
    case Enum.find(categories(), &(&1.id == id)) do
      nil -> ""
      category -> category.label
    end
  end
end
