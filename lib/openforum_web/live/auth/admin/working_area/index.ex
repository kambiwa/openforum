defmodule OpenforumWeb.Auth.WorkingAreas.Index do
  use OpenforumWeb, :live_view

  alias Openforum.Context.WorkingAreas
  alias Openforum.Accounts.User
  alias OpenforumWeb.Schema.UserWorkingAreaMembership
  alias OpenforumWeb.Schema.WorkingArea

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Working Areas")
     |> assign(:current_page, :working_areas)
     |> assign(:areas, [])
     |> assign(:hierarchy_rows, [])
     |> assign(:selected_area, nil)
     |> assign(:memberships, [])
     |> assign(:available_users, [])
     |> assign(:parent_options, [])
     |> assign(:search_filter, "")
     |> assign(:status_filter, "")
     |> assign(:working_area, nil)
     |> assign(:membership_form, to_form(WorkingAreas.change_membership()))}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    action = socket.assigns.live_action

    working_area =
      case {action, params["id"]} do
        {:edit, id} when is_binary(id) -> WorkingAreas.get_working_area!(id)
        {:new, _} -> %WorkingArea{}
        _ -> nil
      end

    areas = WorkingAreas.list_working_area_tree()
    selected_area = get_area(areas, params["area_id"])

    memberships =
      if selected_area,
        do: WorkingAreas.list_working_area_members(selected_area.id, active_only: false),
        else: []

    {:noreply,
     socket
     |> assign(:areas, areas)
     |> assign(:hierarchy_rows, hierarchy_rows(areas))
     |> assign(:selected_area, selected_area)
     |> assign(:memberships, memberships)
     |> assign(
       :available_users,
       if(selected_area,
         do: WorkingAreas.list_users_available_for_working_area(selected_area.id),
         else: []
       )
     )
     |> assign(:parent_options, WorkingAreas.list_parent_options(working_area && working_area.id))
     |> assign(:working_area, working_area)
     |> assign(:page_title, page_title(action))
     |> assign(
       :membership_form,
       to_form(
         WorkingAreas.change_membership(%UserWorkingAreaMembership{
           starts_on: Date.utc_today(),
           status: "active"
         })
       )
     )}
  end

  @impl true
  def handle_info({OpenforumWeb.Auth.WorkingAreas.FormComponent, {:saved, _area}}, socket) do
    {:noreply, refresh(socket)}
  end

  def handle_info({OpenforumWeb.Auth.WorkingAreas.FormComponent, {:cancelled, _}}, socket) do
    {:noreply, push_patch(socket, to: ~p"/admin/working_areas")}
  end

  @impl true
  def handle_event("new_area", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/admin/working_areas/new")}
  end

  def handle_event("edit_area", %{"id" => id}, socket) do
    {:noreply, push_patch(socket, to: ~p"/admin/working_areas/#{id}/edit")}
  end

  def handle_event("select_area", %{"id" => id}, socket) do
    {:noreply, push_patch(socket, to: ~p"/admin/working_areas?area_id=#{id}")}
  end

  def handle_event("close_form", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/admin/working_areas")}
  end

  def handle_event("filter", %{"filter" => filters}, socket) do
    {:noreply,
     socket
     |> assign(:search_filter, filters["search_filter"] || "")
     |> assign(:status_filter, filters["status_filter"] || "")
     |> refresh()}
  end

  def handle_event("toggle_active", %{"id" => id}, socket) do
    area = WorkingAreas.get_working_area!(id)

    result =
      if area.is_active,
        do: WorkingAreas.deactivate_working_area(area),
        else: WorkingAreas.activate_working_area(area)

    case result do
      {:ok, _area} ->
        {:noreply, refresh(socket)}

      {:error, changeset} ->
        {:noreply,
         put_flash(socket, :error, "Could not update area: #{inspect(changeset.errors)}")}
    end
  end

  def handle_event(
        "assign_member",
        %{"membership" => params},
        %{assigns: %{selected_area: %WorkingArea{} = area}} = socket
      ) do
    case WorkingAreas.assign_user_to_working_area(
           params["user_id"],
           area.id,
           Map.drop(params, ["user_id"])
         ) do
      {:ok, _membership} ->
        {:noreply,
         socket
         |> put_flash(:info, "User membership saved.")
         |> refresh()}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :membership_form, to_form(changeset))}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Could not assign user: #{inspect(reason)}")}
    end
  end

  def handle_event("assign_member", _params, socket),
    do: {:noreply, put_flash(socket, :error, "Select a working area first.")}

  def handle_event(
        "remove_member",
        %{"user-id" => user_id},
        %{assigns: %{selected_area: %WorkingArea{} = area}} = socket
      ) do
    case WorkingAreas.remove_user_from_working_area(user_id, area.id) do
      {:ok, _membership} ->
        {:noreply,
         socket
         |> put_flash(:info, "Membership deactivated.")
         |> refresh()}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Could not remove membership: #{inspect(reason)}")}
    end
  end

  defp refresh(socket) do
    areas = WorkingAreas.list_working_area_tree()
    selected = socket.assigns.selected_area && get_area(areas, socket.assigns.selected_area.id)

    socket
    |> assign(:areas, areas)
    |> assign(:hierarchy_rows, hierarchy_rows(areas))
    |> assign(:selected_area, selected)
    |> assign(
      :memberships,
      if(selected,
        do: WorkingAreas.list_working_area_members(selected.id, active_only: false),
        else: []
      )
    )
    |> assign(
      :available_users,
      if(selected, do: WorkingAreas.list_users_available_for_working_area(selected.id), else: [])
    )
    |> assign(
      :parent_options,
      WorkingAreas.list_parent_options(
        socket.assigns.working_area && socket.assigns.working_area.id
      )
    )
  end

  defp get_area(_areas, nil), do: nil
  defp get_area(areas, id), do: Enum.find(areas, &(to_string(&1.id) == to_string(id)))

  defp page_title(:new), do: "New Working Area"
  defp page_title(:edit), do: "Edit Working Area"
  defp page_title(_), do: "Working Areas"

  defp hierarchy_rows(areas) do
    children = Enum.group_by(areas, & &1.parent_id)
    flatten(children[nil] || [], children, 0)
  end

  defp flatten(areas, children, depth) do
    Enum.flat_map(areas, fn area ->
      [%{area: area, depth: depth} | flatten(children[area.id] || [], children, depth + 1)]
    end)
  end

  defp full_name(%User{first_name: first, last_name: last}) do
    String.trim("#{first || ""} #{last || ""}")
  end

  defp membership_state(%UserWorkingAreaMembership{status: "inactive"}), do: "Inactive"

  defp membership_state(%UserWorkingAreaMembership{starts_on: starts_on, ends_on: ends_on}) do
    today = Date.utc_today()

    cond do
      starts_on && Date.compare(starts_on, today) == :gt -> "Scheduled"
      ends_on && Date.compare(ends_on, today) == :lt -> "Expired"
      true -> "Active"
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.admin_app flash={@flash} current_scope={@current_scope} current_page={:working_areas}>
      <div class="flex flex-col gap-6 p-6">
        <div class="flex flex-wrap items-end justify-between gap-3">
          <div>
            <h1 class="text-[1.1rem] font-bold text-[#0B2E4F]">Working Area Management</h1>
            <p class="mt-1 text-[0.82rem] text-[#6B7280]">
              Configure the organisation hierarchy and area memberships.
            </p>
          </div>
          <button
            id="new-working-area"
            phx-click="new_area"
            class="inline-flex items-center gap-2 rounded-lg bg-[#1769AA] px-4 py-2 text-sm font-medium text-white transition hover:bg-[#0B2E4F]"
          >
            <.icon name="hero-plus" class="size-4" /> New working area
          </button>
        </div>

        <.form
          for={%{}}
          as={:filter}
          id="working-area-filter"
          phx-change="filter"
          class="grid gap-3 rounded-xl border border-[#E5E7EB] bg-white p-4 sm:grid-cols-[1fr_220px]"
        >
          <.input
            name="filter[search_filter]"
            value={@search_filter}
            placeholder="Search working areas"
          />
          <.input
            type="select"
            name="filter[status_filter]"
            value={@status_filter}
            prompt="All statuses"
            options={[{"Active", "active"}, {"Inactive", "inactive"}]}
          />
        </.form>

        <div class="grid gap-6 xl:grid-cols-[minmax(0,1.2fr)_minmax(360px,0.8fr)]">
          <section class="overflow-hidden rounded-xl border border-[#E5E7EB] bg-white">
            <div class="border-b border-[#E5E7EB] px-5 py-4">
              <h2 class="font-semibold text-[#0B2E4F]">Organisational hierarchy</h2>
              <p class="mt-1 text-xs text-[#6B7280]">
                Areas are displayed by configured order, with no fixed level limit.
              </p>
            </div>
            <div id="working-area-tree" class="divide-y divide-[#F1F3F5]">
              <div
                :for={row <- filtered_rows(@hierarchy_rows, @search_filter, @status_filter)}
                id={"working-area-#{row.area.id}"}
                class={[
                  "flex items-center justify-between gap-3 px-5 py-3 transition hover:bg-[#F8FAFC]",
                  @selected_area && @selected_area.id == row.area.id && "bg-[#EAF3F8]"
                ]}
              >
                <button
                  type="button"
                  phx-click="select_area"
                  phx-value-id={row.area.id}
                  class="min-w-0 flex-1 text-left"
                  style={"padding-left: #{min(row.depth * 20, 120)}px"}
                >
                  <span class="block truncate text-sm font-medium text-[#252525]">{row.area.name}</span>
                  <span class="mt-0.5 block truncate text-xs text-[#6B7280]">{row.area.description ||
                    "No description"}</span>
                </button>
                <span class={[
                  "rounded-full px-2 py-1 text-[0.68rem] font-medium",
                  if(row.area.is_active,
                    do: "bg-emerald-50 text-emerald-700",
                    else: "bg-slate-100 text-slate-600"
                  )
                ]}>{if row.area.is_active, do: "Active", else: "Inactive"}</span>
                <button
                  type="button"
                  phx-click="edit_area"
                  phx-value-id={row.area.id}
                  aria-label={"Edit #{row.area.name}"}
                  class="rounded-md p-2 text-[#1769AA] transition hover:bg-[#EAF3F8]"
                ><.icon name="hero-pencil-square" class="size-4" /></button>
                <button
                  type="button"
                  phx-click="toggle_active"
                  phx-value-id={row.area.id}
                  class="rounded-md px-2 py-1 text-xs text-[#6B7280] hover:bg-slate-100"
                >{if row.area.is_active, do: "Deactivate", else: "Activate"}</button>
              </div>
              <div
                :if={filtered_rows(@hierarchy_rows, @search_filter, @status_filter) == []}
                class="px-5 py-10 text-center text-sm text-[#6B7280]"
              >
                No working areas match these filters.
              </div>
            </div>
          </section>

          <section class="rounded-xl border border-[#E5E7EB] bg-white">
            <div class="border-b border-[#E5E7EB] px-5 py-4">
              <h2 class="font-semibold text-[#0B2E4F]">Area membership</h2>
              <p class="mt-1 text-xs text-[#6B7280]">
                {if @selected_area, do: @selected_area.name, else: "Select an area in the hierarchy"}
              </p>
            </div>
            <div :if={@selected_area} class="p-5">
              <.form
                for={@membership_form}
                id="membership-form"
                phx-submit="assign_member"
                class="grid gap-3"
              >
                <.input
                  field={@membership_form[:user_id]}
                  type="select"
                  label="User"
                  prompt="Choose a user"
                  options={Enum.map(@available_users, &{user_label(&1), &1.id})}
                />
                <div class="grid grid-cols-2 gap-3">
                  <.input field={@membership_form[:starts_on]} type="date" label="Effective from" />
                  <.input
                    field={@membership_form[:ends_on]}
                    type="date"
                    label="Effective until (optional)"
                  />
                </div>
                <button
                  type="submit"
                  class="rounded-lg bg-[#1769AA] px-4 py-2 text-sm font-medium text-white transition hover:bg-[#0B2E4F]"
                >Assign user</button>
              </.form>

              <div class="mt-5 divide-y divide-[#E5E7EB] border-t border-[#E5E7EB]">
                <div
                  :for={membership <- @memberships}
                  id={"membership-#{membership.id}"}
                  class="flex items-center justify-between gap-3 py-3"
                >
                  <div class="min-w-0">
                    <p class="truncate text-sm font-medium text-[#252525]">
                      {full_name(membership.user)}
                    </p>
                    <p class="truncate text-xs text-[#6B7280]">
                      {membership.user.email} · {membership.starts_on}{if membership.ends_on,
                        do: " – #{membership.ends_on}",
                        else: ""}
                    </p>
                  </div>
                  <div class="flex items-center gap-2">
                    <span class="rounded-full bg-[#EAF3F8] px-2 py-1 text-[0.68rem] text-[#1769AA]">{membership_state(
                      membership
                    )}</span>
                    <button
                      :if={membership.status == "active"}
                      type="button"
                      phx-click="remove_member"
                      phx-value-user-id={membership.user_id}
                      class="rounded-md px-2 py-1 text-xs text-red-600 hover:bg-red-50"
                    >Remove</button>
                  </div>
                </div>
                <p :if={@memberships == []} class="py-6 text-center text-sm text-[#6B7280]">
                  No memberships recorded for this area.
                </p>
              </div>
            </div>
            <p :if={!@selected_area} class="p-8 text-center text-sm text-[#6B7280]">
              Choose a working area to manage its members.
            </p>
          </section>
        </div>

        <.modal
          :if={@live_action in [:new, :edit]}
          id="working-area-modal"
          show
          on_cancel={JS.push("close_form")}
        >
          <.live_component
            module={OpenforumWeb.Auth.WorkingAreas.FormComponent}
            id={@working_area.id || :new}
            title={@page_title}
            action={@live_action}
            working_area={@working_area}
            parent_options={@parent_options}
            patch={~p"/admin/working_areas"}
          />
        </.modal>
      </div>
    </Layouts.admin_app>
    """
  end

  defp filtered_rows(rows, search, status) do
    search = String.downcase(search || "")

    Enum.filter(rows, fn %{area: area} ->
      matches_search =
        search == "" or
          String.contains?(String.downcase(area.name <> " " <> (area.description || "")), search)

      matches_status =
        status in [nil, ""] or (status == "active" and area.is_active) or
          (status == "inactive" and not area.is_active)

      matches_search and matches_status
    end)
  end

  defp user_label(%User{} = user), do: "#{full_name(user)} (#{user.email})"
end
