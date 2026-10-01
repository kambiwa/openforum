defmodule OpenforumWeb.Auth.Document.Index do
  use OpenforumWeb, :live_view

  alias OpenforumWeb.PaginationComponent
  alias Openforum.Context.Documents
  alias OpenforumWeb.Pagination
  alias OpenforumWeb.Datatable.Table
  alias Openforum.Schema.ContentItem

  @impl true
  def mount(_params, _session, socket) do
    IO.inspect(socket.assigns.current_scope, label: "=========Current Scope in Document Index")
    socket =
      socket
      |> assign(:page_title, "My Documents")
      |> assign(:data, [])
      |> assign(:data_pagenations, %{})
      |> assign(:categories, Documents.list_categories_for_select())
      |> assign(:search_filter, "")
      |> assign(:category_filter, "")
      |> assign(:filter_expanded, false)
      |> assign(:document, nil)
      |> assign(:live_action, :index)
      |> Pagination.order_by_composer()
      |> Pagination.i_search_composer()

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply,
     socket
     |> assign(:params, params)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Document")
    |> assign(:document, Documents.get_document!(current_user(socket), id))
  end

  defp apply_action(socket, :view, %{"id" => id}) do
    socket
    |> assign(:page_title, "View Document")
    |> assign(:document, Documents.get_document!(current_user(socket), id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Document")
    |> assign(:document, %ContentItem{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "My Documents")
    |> assign(:document, nil)
    |> fetch_filtered_documents()
  end

  # ── FormComponent messages ──────────────────────────────────────────

  @impl true
  def handle_info({OpenforumWeb.Auth.Document.FormComponent, {:saved, _document}}, socket) do
    {:noreply, socket |> assign(:live_action, :index) |> fetch_filtered_documents()}
  end

  def handle_info({OpenforumWeb.Auth.Document.FormComponent, {:submitted, document}}, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "\"#{document.title}\" submitted for review.")
     |> assign(:live_action, :index)
     |> fetch_filtered_documents()}
  end

  def handle_info({OpenforumWeb.Auth.Document.FormComponent, {:cancelled, _}}, socket) do
    {:noreply, assign(socket, :live_action, :index)}
  end

  # ── Row / page actions ───────────────────────────────────────────────

  @impl true
  def handle_event("new_document", _params, socket) do

    {:noreply,
     socket
     |> assign(:page_title, "New Document")
     |> assign(:document, %ContentItem{})
     |> assign(:live_action, :new)}
  end

  def handle_event("edit", %{"id" => id}, socket) do
    {:noreply,
     socket
     |> assign(:page_title, "Edit Document")
     |> assign(:document, Documents.get_document!(current_user(socket), id))
     |> assign(:live_action, :edit)}
  end

  def handle_event("view", %{"id" => id}, socket) do
    {:noreply,
     socket
     |> assign(:page_title, "View Document")
     |> assign(:document, Documents.get_document!(current_user(socket), id))
     |> assign(:live_action, :view)}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    document = Documents.get_document!(current_user(socket), id)

    case Documents.delete_document(document) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "\"#{document.title}\" deleted.")
         |> fetch_filtered_documents()}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not delete \"#{document.title}\".")}
    end
  end

  def handle_event("close", _params, socket) do
    {:noreply, socket |> assign(:live_action, :index) |> fetch_filtered_documents()}
  end

  def handle_event("toggle-filter", _, socket) do
    {:noreply, assign(socket, filter_expanded: !socket.assigns.filter_expanded)}
  end

  def handle_event("filter", %{"filter" => filters}, socket) do
    {:noreply,
     socket
     |> assign(:search_filter, filters["search_filter"] || "")
     |> assign(:category_filter, filters["category_filter"] || "")
     |> fetch_filtered_documents()}
  end

  defp fetch_filtered_documents(socket) do
    filters = %{search_filter: socket.assigns.search_filter, category_filter: socket.assigns.category_filter}

    data =
      Documents.list_documents(
        current_user(socket),
        Pagination.create_table_params(socket, socket.assigns.params),
        filters
      )

    socket
    |> assign(:data, data.entries)
    |> assign(:data_pagenations, Map.drop(data, [:entries]))
  end

  defp current_user(socket), do: socket.assigns.current_scope.user

  # ── Render ──────────────────────────────────────────────────────────

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.admin_app flash={@flash} current_scope={@current_scope} current_page={:documents}>
      <div class="flex flex-col gap-6 p-6">
        <div class="flex items-center justify-between">
          <div>
            <h1 class="mb-0.5 text-[1.1rem] font-bold text-[#0B2E4F]">My Documents</h1>
            <p class="text-[0.82rem] text-[#6B7280]">
              Content you're writing before it goes out for review.
            </p>
          </div>

          <div class="flex items-center gap-3">
            <button
              phx-click="toggle-filter"
              class="inline-flex items-center gap-1.5 rounded-lg border border-[#E5E7EB] bg-white px-4 py-2 text-[0.82rem] font-medium text-[#0B2E4F] hover:bg-[#EAF3F8]"
            >
              <.icon name="hero-funnel" class="size-4" /> Filter
            </button>

            <button
              phx-click="new_document"
              class="inline-flex items-center gap-1.5 rounded-lg bg-[#1769AA] px-4 py-2 text-[0.82rem] font-medium text-white hover:bg-[#0B2E4F]"
            >
              <.icon name="hero-plus" class="size-4" /> New Document
            </button>
          </div>
        </div>

        <div
          :if={@filter_expanded}
          class="rounded-xl border border-[#E5E7EB] border-t-[3px] border-t-[#1769AA] bg-white p-5"
        >
          <.form for={%{}} as={:filter} phx-change="filter">
            <div class="grid grid-cols-2 gap-4">
              <div class="flex flex-col gap-1.5">
                <label class="text-xs font-medium text-[#0B2E4F]">Search</label>
                <.input name="filter[search_filter]" placeholder="Search documents..." value={@search_filter} />
              </div>

              <div class="flex flex-col gap-1.5">
                <label class="text-xs font-medium text-[#0B2E4F]">Category</label>
                <.input
                  type="select"
                  name="filter[category_filter]"
                  prompt="All"
                  options={@categories}
                  value={@category_filter}
                />
              </div>
            </div>
          </.form>
        </div>

        <div class="overflow-hidden rounded-xl border border-[#E5E7EB] bg-white">
          <Table.table id="tbl_documents" rows={@data}>
            <:col :let={document} label="Title">
              <span class="font-medium text-[#252525]">{document.title}</span>
            </:col>

            <:col :let={document} label="Category">
              <span class="text-[#6B7280]">{document.category && document.category.name}</span>
            </:col>

            <:col :let={document} label="Updated">
              <span class="text-[#6B7280]">{document.updated_at}</span>
            </:col>

            <:col :let={document} label="Status">
              <span class="text-[#6B7280]">{document.status}</span>
            </:col>

            <:action :let={document}>
             <button
                phx-click="view"
                phx-value-id={document.id}
                class="inline-flex items-center gap-1 rounded-md bg-[#EAF3F8] px-2.5 py-1 text-xs font-medium text-[#1769AA] hover:bg-[#4F7FA8]/20"
              >
                <.icon name="hero-pencil-square" class="size-3" /> View
              </button>
              <button
                phx-click="edit"
                phx-value-id={document.id}
                class="inline-flex items-center gap-1 rounded-md bg-[#EAF3F8] px-2.5 py-1 text-xs font-medium text-[#1769AA] hover:bg-[#4F7FA8]/20"
              >
                <.icon name="hero-pencil-square" class="size-3" /> Edit
              </button>

              <button
                phx-click="delete"
                phx-value-id={document.id}
                data-confirm={"Delete \"#{document.title}\"? This cannot be undone."}
                class="inline-flex items-center gap-1 rounded-md bg-red-50 px-2.5 py-1 text-xs font-medium text-red-600 hover:bg-red-100"
              >
                <.icon name="hero-trash" class="size-3" /> Delete
              </button>
            </:action>
          </Table.table>

          <p :if={@data == []} class="p-10 text-center text-sm text-[#6B7280]">
            No documents yet — start a new one above.
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
          :if={@live_action in [:new, :edit]}
          id={"document-modal-#{(@document && @document.id) || :new}"}
          show
          on_cancel={JS.push("close")}
        >
          <.live_component
            module={OpenforumWeb.Auth.Document.FormComponent}
            id={(@document && @document.id) || :new}
            title={@page_title}
            action={@live_action}
            document={@document}
            current_user={@current_scope.user}
          />
        </.modal>
      </div>
    </Layouts.admin_app>
    """
  end
end
