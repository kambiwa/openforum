defmodule OpenforumWeb.Auth.Users.Index do
  use OpenforumWeb, :live_view

  alias OpenforumWeb.Datatable.Table
  alias OpenforumWeb.Pagination
  alias Openforum.Accounts.User
  alias Openforum.Accounts
  alias Openforum.Repo
  alias OpenforumWeb.UserAuth

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

  defp apply_action(socket, :view, %{"id" => id}) do
    user = Accounts.get_user!(id) |> Repo.preload(:roles)

    socket
    |> assign(:page_title, "User Details")
    |> assign(:user, user)
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

  def handle_event("view", %{"id" => id}, socket) do
    user = Accounts.get_user!(id) |> Repo.preload(:roles)

    {:noreply,
     socket
     |> assign(:page_title, "User Details")
     |> assign(:user, user)
     |> assign(:live_action, :view)}
  end

  def handle_event("toggle_user_active", %{"id" => id}, socket) do
    user = Accounts.get_user!(id)
    current_user = socket.assigns.current_scope.user

    cond do
      user.id == current_user.id and user.is_active ->
        {:noreply, put_flash(socket, :error, "You cannot deactivate your own account.")}

      true ->
        active? = not user.is_active

        case Accounts.set_user_active(user, active?) do
          {:ok, _updated_user, tokens} ->
            UserAuth.disconnect_sessions(tokens)

            message =
              if active?,
                do: "User activated successfully.",
                else: "User deactivated successfully."

            {:noreply, socket |> fetch_filtered_users() |> put_flash(:info, message)}

          {:error, changeset} ->
            {:noreply,
             put_flash(
               socket,
               :error,
               "Could not update user status: #{inspect(changeset.errors)}"
             )}
        end
    end
  end

  def handle_event("delete_user", %{"id" => id}, socket) do
    user = Accounts.get_user!(id)

    if user.id == socket.assigns.current_scope.user.id do
      {:noreply, put_flash(socket, :error, "You cannot delete your own account.")}
    else
      case Accounts.delete_user(user) do
        {:ok, _deleted_user} ->
          {:noreply,
           socket |> fetch_filtered_users() |> put_flash(:info, "User deleted successfully.")}

        {:error, _changeset} ->
          {:noreply,
           put_flash(
             socket,
             :error,
             "Could not delete this user because related records still exist."
           )}
      end
    end
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

          <Table.table id="tbl_users" rows={@data} loading={@data_loader} striped>
            <:col :let={user} label="Profile">
              <img
                :if={user.avatar_url}
                src={user.avatar_url}
                alt={"#{user.first_name} #{user.last_name}"}
                class="size-10 rounded-full object-cover ring-2 ring-[#EAF3F8]"
              />
              <span
                :if={!user.avatar_url}
                class="flex size-10 items-center justify-center rounded-full bg-[#0B2E4F] text-xs font-bold uppercase text-white"
              >
                {user_initials(user)}
              </span>
            </:col>
            <:col :let={user} label="First name">
              <span class="font-medium text-[#252525]">{user.first_name}</span>
            </:col>
            <:col :let={user} label="Last name">
              <span class="font-medium text-[#252525]">{user.last_name}</span>
            </:col>
            <:col :let={user} label="Role">
              <span :if={user.roles == []} class="text-[#9CA3AF]">No role assigned</span>
              <span :if={user.roles != []} class="text-[#6B7280]">
                {Enum.map_join(user.roles, ", ", & &1.name)}
              </span>
            </:col>

            <:action :let={user}>
              <button
                type="button"
                phx-click="view"
                phx-value-id={user.id}
                class="flex w-full items-center gap-2 rounded-lg px-3 py-2 text-left text-xs font-medium text-[#34495E] transition-colors hover:bg-[#F4F8FB]"
              >
                <.icon name="hero-eye" class="size-4" /> View
              </button>
              <button
                type="button"
                phx-click="edit"
                phx-value-id={user.id}
                class="flex w-full items-center gap-2 rounded-lg px-3 py-2 text-left text-xs font-medium text-[#34495E] transition-colors hover:bg-[#F4F8FB]"
              >
                <.icon name="hero-pencil-square" class="size-4" /> Edit
              </button>
              <button
                type="button"
                phx-click="toggle_user_active"
                phx-value-id={user.id}
                class="flex w-full items-center gap-2 rounded-lg px-3 py-2 text-left text-xs font-medium text-amber-700 transition-colors hover:bg-amber-50"
              >
                <.icon
                  name={if(user.is_active, do: "hero-no-symbol", else: "hero-check-circle")}
                  class="size-4"
                />
                {if(user.is_active, do: "Deactivate", else: "Activate")}
              </button>
              <button
                type="button"
                phx-click="delete_user"
                phx-value-id={user.id}
                data-confirm={"Delete #{user.first_name} #{user.last_name}? This cannot be undone."}
                class="flex w-full items-center gap-2 rounded-lg px-3 py-2 text-left text-xs font-medium text-rose-600 transition-colors hover:bg-rose-50"
              >
                <.icon name="hero-trash" class="size-4" /> Delete
              </button>
            </:action>
          </Table.table>

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
          :if={@live_action == :view && @user}
          id={"view-user-modal-#{@user.id}"}
          show
          on_cancel={JS.push("close")}
        >
          <div class="space-y-6 p-6">
            <div class="flex items-center gap-4">
              <img
                :if={@user.avatar_url}
                src={@user.avatar_url}
                alt=""
                class="size-16 rounded-full object-cover"
              />
              <span
                :if={!@user.avatar_url}
                class="flex size-16 items-center justify-center rounded-full bg-[#0B2E4F] text-lg font-bold text-white"
              >
                {user_initials(@user)}
              </span>
              <div>
                <h2 class="text-lg font-bold text-[#0B2E4F]">
                  {@user.first_name} {@user.last_name}
                </h2>
                <p class="text-sm text-[#6B7280]">{@user.email}</p>
              </div>
            </div>

            <div class="space-y-3 border-t border-[#E5E7EB] pt-4">
              <p class="text-xs font-semibold uppercase tracking-wide text-[#6B7280]">
                Assigned roles
              </p>
              <div class="flex flex-wrap gap-2">
                <span
                  :for={role <- @user.roles}
                  class="rounded-full bg-[#EAF3F8] px-3 py-1 text-xs font-semibold text-[#1769AA]"
                >
                  {role.name}
                </span>
                <span :if={@user.roles == []} class="text-sm text-[#9CA3AF]">No roles assigned</span>
              </div>
              <p class="text-sm text-[#6B7280]">
                Account status:
                <span class={
                  if(@user.is_active,
                    do: "font-semibold text-emerald-700",
                    else: "font-semibold text-rose-700"
                  )
                }>
                  {if(@user.is_active, do: "Active", else: "Inactive")}
                </span>
              </p>
            </div>
          </div>
        </.modal>

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

  defp user_initials(user) do
    initials =
      [user.first_name, user.last_name]
      |> Enum.map_join(fn
        name when is_binary(name) and name != "" -> String.first(name)
        _ -> ""
      end)
      |> String.upcase()

    if initials == "", do: "?", else: initials
  end
end
