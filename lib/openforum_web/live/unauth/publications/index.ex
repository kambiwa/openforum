defmodule OpenforumWeb.Unauth.Publications.Index do
  use OpenforumWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:mobile_menu_open, false)
      |> assign(:page_title, "Publications — OpenForum")

    {:ok, socket}
  end

end
