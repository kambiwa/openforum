defmodule OpenforumWeb.Unauth.Publications.Index do
  use OpenforumWeb, :live_view

  alias Openforum.Context.Publications

  @impl true
  def mount(_params, _session, socket) do
    categories = Publications.list_public_categories()
    documents = Publications.list_public_content()

    {:ok,
     socket
     |> assign(:mobile_menu_open, false)
     |> assign(:page_title, "Publications — OpenForum")
     |> assign(:categories, categories)
     |> assign(:active_category, "all")
     |> assign(:documents, documents)}
  end

  @impl true
  def handle_event("filter_category", %{"category" => category_id}, socket) do
    valid? =
      category_id == "all" or
        Enum.any?(socket.assigns.categories, &(Integer.to_string(&1.id) == category_id))

    category_id = if valid?, do: category_id, else: "all"
    filter_id = if category_id == "all", do: nil, else: category_id

    {:noreply,
     socket
     |> assign(:active_category, category_id)
     |> assign(:documents, Publications.list_public_content(filter_id))}
  end

  def category_label(%{name: "Bible Content"}), do: "Bible"
  def category_label(%{name: "Doctrine Articles"}), do: "Doctrine"
  def category_label(%{name: "Q&A"}), do: "Questions & Answers"
  def category_label(%{name: name}), do: name
  def category_label(_category), do: "Publication"

  def category_icon(%{slug: "bible-content"}), do: "hero-book-open"
  def category_icon(%{slug: "doctrine-articles"}), do: "hero-academic-cap"
  def category_icon(%{slug: "catechism"}), do: "hero-bookmark"
  def category_icon(%{slug: "qna"}), do: "hero-question-mark-circle"
  def category_icon(_category), do: "hero-document-text"
end
