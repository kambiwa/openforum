defmodule OpenforumWeb.Unauth.Bible.Index do
  use OpenforumWeb, :live_view

  alias Openforum.Bible.Books

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:mobile_menu_open, false)
     |> assign(:page_title, "Bible — OpenForum")
     |> assign(:all_books, Books.all())
     |> assign(:testament, "all")
     |> assign(:query, "")
     |> apply_filters()}
  end

  @impl true
  def handle_event("toggle_mobile_menu", _params, socket) do
    {:noreply, assign(socket, :mobile_menu_open, !socket.assigns.mobile_menu_open)}
  end

  def handle_event("set_testament", %{"testament" => testament}, socket)
      when testament in ~w(all old new) do
    {:noreply, socket |> assign(:testament, testament) |> apply_filters()}
  end

  def handle_event("search", %{"query" => query}, socket) do
    {:noreply, socket |> assign(:query, query) |> apply_filters()}
  end

  def handle_event("clear_filters", _params, socket) do
    {:noreply, socket |> assign(:testament, "all") |> assign(:query, "") |> apply_filters()}
  end

  defp apply_filters(socket) do
    %{all_books: books, testament: testament, query: query} = socket.assigns
    term = query |> String.trim() |> String.downcase()

    filtered =
      Enum.filter(books, fn book ->
        (testament == "all" or Atom.to_string(book.testament) == testament) and
          (term == "" or String.contains?(String.downcase(book.name), term))
      end)

    old = Enum.filter(filtered, &(&1.testament == :old))
    new = Enum.filter(filtered, &(&1.testament == :new))

    socket
    |> assign(:result_count, length(filtered))
    |> assign(:old_groups, Books.group_by_category(old))
    |> assign(:new_groups, Books.group_by_category(new))
    |> assign(:old_count, length(old))
    |> assign(:new_count, length(new))
  end

  defp testament_filters do
    [
      %{id: "all", title: "All Books"},
      %{id: "old", title: "Old Testament"},
      %{id: "new", title: "New Testament"}
    ]
  end
end
