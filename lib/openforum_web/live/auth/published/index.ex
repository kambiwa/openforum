defmodule OpenforumWeb.Auth.Published.Index do
  use OpenforumWeb, :live_view

  alias Openforum.Context.Publications
  alias OpenforumWeb.Datatable.Table
  alias OpenforumWeb.Pagination
  alias OpenforumWeb.PaginationComponent

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Publication Management")
     |> assign(:current_page, :published)
     |> assign(:params, %{})
     |> assign(:data, [])
     |> assign(:pagination_data, %{})
     |> assign(:status_filter, "")
     |> assign(:search_filter, "")
     |> Pagination.order_by_composer()
     |> Pagination.i_search_composer()}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply,
     socket
     |> assign(:params, params)
     |> fetch_content()}
  end

  @impl true
  def handle_event("filter", %{"filter" => filters}, socket) do
    {:noreply,
     socket
     |> assign(:status_filter, filters["status_filter"] || "")
     |> assign(:search_filter, filters["search_filter"] || "")
     |> fetch_content()}
  end

  def handle_event("publish", %{"id" => id}, socket) do
    case Integer.parse(id) do
      {item_id, ""} ->
        case Publications.publish_approved_content(item_id) do
          {:ok, item} ->
            {:noreply,
             socket
             |> fetch_content()
             |> put_flash(:info, "#{item.title} is now published.")}

          {:error, :not_pending_publication} ->
            {:noreply, put_flash(socket, :error, "This item is no longer awaiting publication.")}
        end

      _ ->
        {:noreply, put_flash(socket, :error, "Could not publish this item.")}
    end
  end

  defp fetch_content(socket) do
    result =
      Publications.list_admin_content(
        Pagination.create_table_params(socket, socket.assigns.params),
        %{
          status_filter: socket.assigns.status_filter,
          search_filter: socket.assigns.search_filter
        }
      )

    socket
    |> assign(:data, result.entries)
    |> assign(:pagination_data, Map.drop(result, [:entries]))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.admin_app flash={@flash} current_scope={@current_scope} current_page={@current_page}>
      <div class="flex flex-col gap-6 p-6">
        <header class="flex flex-wrap items-end justify-between gap-4">
          <div>
            <p class="text-xs font-semibold uppercase tracking-[0.14em] text-[#1769AA]">
              Publication
            </p>
            <h1 class="mt-1 text-2xl font-bold tracking-tight text-[#0B2E4F]">
              Publication management
            </h1>
            <p class="mt-2 text-sm text-[#6B7280]">
              Final approvals stay here until they are published.
            </p>
          </div>
        </header>

        <div class="overflow-hidden rounded-xl border border-[#E5E7EB] bg-white">
          <div class="border-b border-[#E5E7EB] px-5 py-4">
            <h2 class="text-sm font-semibold text-[#0B2E4F]">Approved and published content</h2>
          </div>

          <div class="border-b border-[#E5E7EB] bg-[#FCFDFE] p-4">
            <.form for={%{}} as={:filter} phx-change="filter" id="publication-filter-form">
              <div class="grid gap-3 sm:grid-cols-2">
                <.input
                  name="filter[search_filter]"
                  placeholder="Search title or summary"
                  value={@search_filter}
                  aria-label="Search approved and published content"
                />
                <.input
                  type="select"
                  name="filter[status_filter]"
                  prompt="All publication states"
                  options={[
                    {"Approved · Pending publication", "approved"},
                    {"Published", "published"}
                  ]}
                  value={@status_filter}
                />
              </div>
            </.form>
          </div>

          <Table.table
            id="tbl_publications"
            rows={@data}
            striped
            empty_message="No approved or published content matches these filters."
          >
            <:col :let={item} label="Title">
              <span class="font-medium text-[#252525]">{item.title}</span>
            </:col>
            <:col :let={item} label="Category">
              <span class="text-[#6B7280]">{item.category && item.category.name}</span>
            </:col>
            <:col :let={item} label="Author">
              <span class="text-[#6B7280]">
                {if item.author,
                  do: "#{item.author.first_name} #{item.author.last_name}",
                  else: "Unknown"}
              </span>
            </:col>
            <:col label="Status" status_field={:status}></:col>
            <:col :let={item} label="Published">
              <span class="text-[#6B7280]">
                {if item.published_at, do: Calendar.strftime(item.published_at, "%d %b %Y"), else: "—"}
              </span>
            </:col>

            <:action :let={item}>
              <button
                :if={item.status == "approved"}
                type="button"
                phx-click="publish"
                phx-value-id={item.id}
                data-confirm={"Publish #{item.title} now? It will become publicly available."}
                class="flex w-full items-center gap-2 rounded-lg px-3 py-2 text-left text-xs font-semibold text-emerald-700 transition-colors hover:bg-emerald-50"
              >
                <.icon name="hero-globe-alt" class="size-4" /> Publish now
              </button>
              <span :if={item.status == "published"} class="px-3 py-2 text-xs text-[#8A9AAA]">
                Already published
              </span>
            </:action>
          </Table.table>

          <div class="border-t border-[#E5E7EB]">
            <.live_component
              module={PaginationComponent}
              id="PublicationPagination"
              params={@params}
              pagination_data={@pagination_data}
            />
          </div>
        </div>
      </div>
    </Layouts.admin_app>
    """
  end
end
