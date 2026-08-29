defmodule OpenforumWeb.Auth.Users.Index do
  use OpenforumWeb, :live_view

  alias OpenforumWeb.PaginationComponent
  alias OpenforumWeb.Datatable.Table
  alias OpenforumWeb.Pagination
  alias Openforum.Accounts.User
  alias Openforum.Accounts
  alias OpenforumWeb.Repo

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Users")
      |> assign(:data_loader, false)
      |> assign(:data, [])
      |> assign(:data_pagenations, [])
      |> assign(filter_expanded: false)
      |> assign(:status_filter, "")
      |> assign(:search_filter, "")
      |> assign(:user, %User{})
      |> Pagination.order_by_composer()
      |> Pagination.i_search_composer()

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply,
     socket
     |> assign(params: %{})
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit User")
    |> assign(:user, Accounts.get_user!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New User")
    |> assign(:user, %User{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Users")
    |> assign(:user, nil)
    |> fetch_filtered_users()
  end

  @impl true
  def handle_info(
        {OpenforumWeb.Auth.Users.FormComponet, {:saved, _user}},
        socket
      ) do
    {:noreply, fetch_filtered_users(socket)}
  end

  def handle_info(
        {OpenforumWeb.Auth.Users.FormComponet, {:cancelled, _}},
        socket
      ) do
    {:noreply, assign(socket, :live_action, :index)}
  end

  @impl true
  def handle_event("add_user", _params, socket) do
    {:noreply,
     socket
     |> assign(:page_title, "New User")
     |> assign(:user, %User{})
     |> assign(:live_action, :new)}
  end

  def handle_event("edit", %{"id" => id}, socket) do
    {:noreply,
     socket
     |> assign(:page_title, "Edit User")
     |> assign(:user, Accounts.get_user!(id))
     |> assign(:live_action, :edit)}
  end

  @impl true
  def handle_event("close", _params, socket) do
    {:noreply, assign(socket, :live_action, :index)}
  end

  @impl true
  def handle_event("toggle-filter", _, socket) do
    {:noreply, assign(socket, filter_expanded: !socket.assigns.filter_expanded)}
  end

  @impl true
  def handle_event("filter", %{"filter" => filters} = _params, socket) do
    {:noreply,
     socket
     |> assign(:status_filter, filters["status_filter"])
     |> assign(:search_filter, filters["search_filter"])
     |> fetch_filtered_users()}
  end

  defp fetch_filtered_users(socket) do
    filters = %{
      search_filter: socket.assigns.search_filter,
      status_filter: socket.assigns.status_filter
    }

    data =
      Accounts.list_users(
        Pagination.create_table_params(socket, socket.assigns.params),
        filters
      )

    socket
    |> assign(:data, data.entries)
    |> assign(:data_pagenations, Map.drop(data, [:entries]))
    |> assign(data_loader: false)
  end

  # ── Render ───────────────────────────────────────────────────────────

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.admin_app flash={@flash} current_scope={@current_scope} current_page={:users}>
      <div class="flex flex-col gap-6 p-6">
        <%!-- ══ PAGE HEADER ══ --%>
        <div class="flex items-center justify-between">
          <div>
            <h1 class="mb-0.5 text-[1.1rem] font-bold text-[#0B2E4F]">
              User Management
            </h1>
            <p class="text-[0.82rem] text-[#6B7280]">
              Manage user listings and their details.
            </p>
          </div>

          <div class="flex items-center gap-3">
            <%!-- Filter toggle --%>
            <button
              phx-click="toggle-filter"
              class="inline-flex items-center gap-1.5 rounded-lg border border-[#E5E7EB] bg-white px-4 py-2 text-[0.82rem] font-medium text-[#0B2E4F] transition-colors hover:bg-[#EAF3F8]"
            >
              <.icon name="hero-funnel" class="size-4" /> Filter
            </button>

            <%!-- New user --%>
            <button
              phx-click="add_user"
              class="inline-flex items-center gap-1.5 rounded-lg bg-[#1769AA] px-4 py-2 text-[0.82rem] font-medium text-white transition-colors hover:bg-[#0B2E4F]"
            >
              <.icon name="hero-plus" class="size-4" /> New User
            </button>
          </div>
        </div>

        <%!-- ══ FILTER PANEL ══ --%>
        <div
          :if={@filter_expanded}
          class="rounded-xl border border-[#E5E7EB] border-t-[3px] border-t-[#1769AA] bg-white p-5"
        >
          <p class="mb-4 text-xs font-semibold uppercase tracking-[0.08em] text-[#0B2E4F]">
            Filters
          </p>
          <.form for={%{}} as={:filter} phx-change="filter">
            <div class="grid grid-cols-3 gap-4">
              <div class="flex flex-col gap-1.5">
                <label class="text-xs font-medium text-[#0B2E4F]">Search</label>
                <.input
                  name="filter[search_filter]"
                  placeholder="Search users..."
                  value={@search_filter}
                />
              </div>

              <div class="flex flex-col gap-1.5">
                <label class="text-xs font-medium text-[#0B2E4F]">Status</label>
                <.input
                  type="select"
                  name="filter[status_filter]"
                  prompt="All"
                  options={[{"Active", "active"}, {"Inactive", "inactive"}]}
                  value={@status_filter}
                />
              </div>
            </div>
          </.form>
        </div>

        <%!-- ══ TABLE CARD ══ --%>
        <div class="overflow-hidden rounded-xl border border-[#E5E7EB] bg-white">
          <div class="border-b border-[#E5E7EB] px-5 py-4">
            <h2 class="text-[0.85rem] font-semibold text-[#0B2E4F]">All Users</h2>
          </div>

          <Table.table id="tbl_users" rows={@data}>
            <:col :let={user} label="Name">
              <span class="font-medium text-[#252525]">{user.first_name} {user.last_name}</span>
            </:col>
            <:col :let={user} label="Email">
              <span class="text-[#6B7280]">{user.email}</span>
            </:col>

            <:action :let={user}>
              <button
                phx-click="edit"
                phx-value-id={user.id}
                class="inline-flex items-center gap-1 rounded-md bg-[#EAF3F8] px-2.5 py-1 text-xs font-medium text-[#1769AA] transition-colors hover:bg-[#4F7FA8]/20"
              >
                <.icon name="hero-pencil-square" class="size-3" /> Edit
              </button>
            </:action>
          </Table.table>

          <%!-- Loading spinner --%>
          <div :if={@data_loader} class="p-10 text-center">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="mx-auto size-8 animate-spin text-[#1769AA]"
              fill="none"
              viewBox="0 0 24 24"
            >
              <circle
                class="opacity-25"
                cx="12"
                cy="12"
                r="10"
                stroke="currentColor"
                stroke-width="4"
              />
              <path
                class="opacity-75"
                fill="currentColor"
                d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962
                       7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
              />
            </svg>
          </div>

          <%!-- Pagination --%>
          <div class="border-t border-[#E5E7EB]">
            <.live_component
              module={OpenforumWeb.PaginationComponent}
              id="PaginationComponent"
              params={@params}
              pagination_data={@data_pagenations}
            />
          </div>
        </div>

        <%!-- ══ MODAL ══ --%>
        <.modal
          :if={@live_action in [:new, :edit]}
          id={"crud-user-modal-#{(@user && @user.id) || :new}"}
          show
          on_cancel={JS.push("close")}
        >
          <.live_component
            module={OpenforumWeb.Auth.Users.FormComponet}
            id={(@user && @user.id) || :new}
            title={@page_title}
            action={@live_action}
            user={@user}
            patch={~p"/admin/users"}
          />
        </.modal>
      </div>
    </Layouts.admin_app>
    """
  end
end
