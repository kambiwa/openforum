defmodule OpenforumWeb.Auth.ApprovalQueue.Index do
  use OpenforumWeb, :live_view

  alias OpenforumWeb.PaginationComponent
  alias OpenforumWeb.Pagination
  alias OpenforumWeb.Datatable.Table
  alias Openforum.Context.Approvals

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Pending Approval")
     |> assign(:data, [])
     |> assign(:data_pagenations, %{})
     |> Pagination.order_by_composer()
     |> Pagination.i_search_composer()}
  end

  @impl true
  def handle_params(params, _url, socket) do
    user = socket.assigns.current_scope.user
    data = Approvals.list_pending_for_reviewer(user, Pagination.create_table_params(socket, params))

    {:noreply,
     socket
     |> assign(:params, params)
     |> assign(:data, data.entries)
     |> assign(:data_pagenations, Map.drop(data, [:entries]))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.admin_app flash={@flash} current_scope={@current_scope} current_page={:approval_queue}>
      <div class="flex flex-col gap-6 p-6">
        <div>
          <h1 class="mb-0.5 text-[1.1rem] font-bold text-[#0B2E4F]">Pending Approval</h1>
          <p class="text-[0.82rem] text-[#6B7280]">Documents waiting for your review.</p>
        </div>

        <div class="overflow-hidden rounded-xl border border-[#E5E7EB] bg-white">
          <Table.table id="tbl_pending" rows={@data}>
            <:col :let={d} label="Title"><span class="font-medium">{d.title}</span></:col>
            <:col :let={d} label="Category">{d.category && d.category.name}</:col>
            <:col :let={d} label="Step">{d.current_step && d.current_step.name}</:col>
            <:col :let={d} label="Submitted">{d.updated_at}</:col>
          </Table.table>

          <p :if={@data == []} class="p-10 text-center text-sm text-[#6B7280]">
            Nothing waiting for your review.
          </p>

          <div class="border-t border-[#E5E7EB]">
            <.live_component
              module={PaginationComponent}
              id="PaginationComponent"
              params={@params}
              pagination_data={@data_pagenations}
            />
          </div>
        </div>
      </div>
    </Layouts.admin_app>
    """
  end
end
