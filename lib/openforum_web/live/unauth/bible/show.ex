defmodule OpenforumWeb.Unauth.Bible.Show do
  use OpenforumWeb, :live_view

  # alias Openforum.Bible.{Books, Text}
  alias Openforum.Bible.Books
  alias Openforum.Bible.Text


  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:mobile_menu_open, false)
     |> assign(:translations, Text.translations())}
  end

  @impl true
  def handle_params(%{"book" => slug, "chapter" => chapter} = params, _uri, socket) do
    translation_id = if params["t"] in Text.translation_ids(), do: params["t"], else: Text.default()

    with %{} = book <- Books.get(slug),
         {number, ""} <- Integer.parse(chapter),
         true <- number >= 1 and number <= book.chapters do
      {prev, next} = Books.adjacent(slug)

      verses =
        case Text.chapter(translation_id, slug, number) do
          {:ok, verses} -> verses
          :error -> nil
        end

      {:noreply,
       socket
       |> assign(:page_title, "#{book.name} #{number} — OpenForum")
       |> assign(:book, book)
       |> assign(:chapter, number)
       |> assign(:translation, Text.get_translation(translation_id))
       |> assign(:verses, verses)
       |> assign(:prev, prev)
       |> assign(:next, next)}
    else
      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "That chapter could not be found.")
         |> push_navigate(to: ~p"/bible")}
    end
  end

  @impl true
  def handle_event("toggle_mobile_menu", _params, socket) do
    {:noreply, assign(socket, :mobile_menu_open, !socket.assigns.mobile_menu_open)}
  end

  defp book_of(slug), do: Books.get(slug)
end
