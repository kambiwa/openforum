defmodule OpenforumWeb.Unauth.Landing.Index do
     use OpenforumWeb, :live_view


     def mount(_params, _session, socket) do
        socket =
          socket
          |> assign(:current_scope, "")
          |> assign(:mobile_menu_open, false)
       {:ok, socket}
     end


end
