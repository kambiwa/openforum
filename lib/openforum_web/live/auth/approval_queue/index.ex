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
     |> assign(:params, %{})
     |> assign(:data, [])
     |> assign(:data_pagenations, %{})
     |> assign(:reviewing, nil)
     |> Pagination.order_by_composer()
     |> Pagination.i_search_composer()}
  end

  @impl true
  def handle_params(params, _url, socket) do
    # :params must be assigned BEFORE fetch_pending/1, because
    # Pagination.create_table_params/2 reads socket.assigns.params.
    {:noreply,
     socket
     |> assign(:params, params)
     |> fetch_pending()}
  end

  # ── Events ──────────────────────────────────────────────────────────

  @impl true
  def handle_event("review", %{"id" => id}, socket) do
    {:noreply, assign(socket, :reviewing, Approvals.get_for_review!(id))}
  end

  def handle_event("close", _params, socket) do
    {:noreply, assign(socket, :reviewing, nil)}
  end

  def handle_event("decide", %{"decision" => decision, "review" => %{"note" => note}}, socket) do
    user = socket.assigns.current_scope.user
    doc = socket.assigns.reviewing

    result =
      case decision do
        "approve" -> Approvals.approve(doc, note, user)
        "reject" -> Approvals.reject(doc, note, user)
      end

    case result do
      {:ok, _} ->
        {:noreply,
         socket
         |> assign(:reviewing, nil)
         |> put_flash(:info, "\"#{doc.title}\" #{decision}d.")
         |> fetch_pending()}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Could not #{decision}: #{inspect(reason)}")}
    end
  end

  # ── Data ────────────────────────────────────────────────────────────

  defp fetch_pending(socket) do
    user = socket.assigns.current_scope.user

    data =
      Approvals.list_pending_for_reviewer(
        user,
        Pagination.create_table_params(socket, socket.assigns.params)
      )

    socket
    |> assign(:data, data.entries)
    |> assign(:data_pagenations, Map.drop(data, [:entries]))
  end

  # ── Render ──────────────────────────────────────────────────────────

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
            <:col :let={d} label="Title">
              <span class="font-medium text-[#252525]">{d.title}</span>
            </:col>

            <:col :let={d} label="Category">
              <span class="text-[#6B7280]">{d.category && d.category.name}</span>
            </:col>

            <:col :let={d} label="Step">
              <span class="text-[#6B7280]">{d.current_step && d.current_step.name}</span>
            </:col>

            <:col :let={d} label="Submitted">
              <span class="text-[#6B7280]">{d.updated_at}</span>
            </:col>

            <:action :let={d}>
              <button
                phx-click="review"
                phx-value-id={d.id}
                class="inline-flex items-center gap-1 rounded-md bg-[#EAF3F8] px-2.5 py-1 text-xs font-medium text-[#1769AA] hover:bg-[#4F7FA8]/20"
              >
                <.icon name="hero-eye" class="size-3" /> Review
              </button>
            </:action>
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

        <.modal
          :if={@reviewing}
          id={"review-modal-#{@reviewing.id}"}
          show
          on_cancel={JS.push("close")}
        >
          <h2 class="text-base font-bold text-[#0B2E4F]">{@reviewing.title}</h2>
          <p class="mt-2 text-sm text-[#6B7280]">{@reviewing.summary}</p>

          <div class="prose prose-sm mt-4 max-w-none">
            {Phoenix.HTML.raw(@reviewing.body)}
          </div>

          <.form for={%{}} as={:review} phx-submit="decide" class="mt-4 flex flex-col gap-3">
            <textarea
              name="review[note]"
              rows="3"
              required
              placeholder="Note (required)"
              class="w-full rounded-lg border border-[#E5E7EB] p-2 text-sm"
            ></textarea>

            <div class="flex justify-end gap-2">
              <button
                type="submit"
                name="decision"
                value="reject"
                class="rounded-lg bg-red-50 px-4 py-2 text-sm font-medium text-red-600 hover:bg-red-100"
              >
                Reject
              </button>
              <button
                type="submit"
                name="decision"
                value="approve"
                class="rounded-lg bg-[#1769AA] px-4 py-2 text-sm font-medium text-white hover:bg-[#0B2E4F]"
              >
                Approve
              </button>
            </div>
          </.form>
        </.modal>
      </div>
    </Layouts.admin_app>
    """
  end
end
