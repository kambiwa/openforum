defmodule OpenforumWeb.Unauth.Media.Index do
  use OpenforumWeb, :live_view

  alias Openforum.Context.Publications

  @impl true
  def mount(_params, _session, socket) do
    items =
      Publications.list_public_media()
      |> Enum.with_index()
      |> Enum.map(fn {resource, index} ->
        %{
          id: resource.id,
          featured: index == 0,
          type: resource.media_type,
          topic: (resource.category && resource.category.name) || "Media",
          title: resource.title,
          description: resource.description || "",
          duration: duration_label(resource.duration_seconds),
          file_url: resource.file_url,
          thumbnail_url: resource.thumbnail_url
        }
      end)

    {:ok,
     socket
     |> assign(:mobile_menu_open, false)
     |> assign(:page_title, "Media — OpenForum")
     |> assign(:content_categories, content_categories())
     |> assign(:workflow_steps, workflow_steps())
     |> assign(:all_items, items)
     |> assign(:featured_item, Enum.find(items, & &1.featured))
     |> assign(:active_category, "all")
     |> assign(:query, "")
     |> assign(:content_items, items)}
  end

  @impl true
  def handle_event("toggle_mobile_menu", _params, socket) do
    {:noreply, assign(socket, :mobile_menu_open, !socket.assigns.mobile_menu_open)}
  end

  def handle_event("filter", %{"category" => category}, socket) do
    {:noreply, socket |> assign(:active_category, category) |> apply_filters()}
  end

  def handle_event("search", %{"query" => query}, socket) do
    {:noreply, socket |> assign(:query, query) |> apply_filters()}
  end

  def handle_event("clear_filters", _params, socket) do
    {:noreply, socket |> assign(:active_category, "all") |> assign(:query, "") |> apply_filters()}
  end

  # ---------- filtering ----------

  defp apply_filters(socket) do
    %{all_items: items, active_category: category, query: query} = socket.assigns
    term = query |> String.trim() |> String.downcase()

    filtered =
      Enum.filter(items, fn item ->
        matches_category?(item, category) and matches_query?(item, term)
      end)

    assign(socket, :content_items, filtered)
  end

  defp matches_category?(_item, "all"), do: true
  defp matches_category?(item, category), do: item.type == category

  defp matches_query?(_item, ""), do: true

  defp matches_query?(item, term) do
    [item.title, item.description, item.topic]
    |> Enum.any?(&String.contains?(String.downcase(&1), term))
  end

  # ---------- view helpers ----------

  defp type_icon("audio"), do: "hero-musical-note"
  defp type_icon("video"), do: "hero-video-camera"
  defp type_icon("presentation"), do: "hero-presentation-chart-bar"
  defp type_icon("document"), do: "hero-document-text"
  defp type_icon(_), do: "hero-play-circle"

  defp type_label("audio"), do: "Audio Teaching"
  defp type_label("video"), do: "Video"
  defp type_label("presentation"), do: "Presentation"
  defp type_label("document"), do: "Document"
  defp type_label(_), do: "Media"

  defp duration_label(nil), do: ""

  defp duration_label(seconds) when seconds < 60, do: "#{seconds} sec"

  defp duration_label(seconds) do
    minutes = div(seconds, 60)
    remainder = rem(seconds, 60)

    if remainder == 0,
      do: "#{minutes} min",
      else: "#{minutes}:#{String.pad_leading(to_string(remainder), 2, "0")}"
  end

  defp content_categories do
    [
      %{id: "all", title: "All Media", icon: "hero-squares-2x2"},
      %{id: "video", title: "Video", icon: "hero-video-camera"},
      %{id: "audio", title: "Audio", icon: "hero-musical-note"},
      %{id: "presentation", title: "Presentations", icon: "hero-presentation-chart-bar"},
      %{id: "document", title: "Documents", icon: "hero-document-text"}
    ]
  end

  defp workflow_steps do
    [
      %{icon: "hero-user-group", title: "Congregation"},
      %{icon: "hero-building-office-2", title: "District Rector Area"},
      %{icon: "hero-flag", title: "Apostle Area"},
      %{icon: "hero-globe-alt", title: "Lead Apostle Area"},
      %{icon: "hero-shield-check", title: "District Apostle Area"}
    ]
  end
end
