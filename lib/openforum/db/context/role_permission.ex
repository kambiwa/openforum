# defmodule OpenforumWeb.Auth.RolesPermissions.Index do
#   use OpenforumWeb, :live_view

#   alias Openforum.Context.Roles

#   @impl true
#   def mount(_params, _session, socket) do
#     roles = Roles.list_roles()
#     permissions_by_category = Roles.list_permissions_by_category()
#     selected = List.first(roles)

#     {:ok,
#      socket
#      |> assign(:current_scope, "")
#      |> assign(:mobile_menu_open, false)
#      |> assign(:page_title, "Roles & Permissions")
#      |> assign(:current_page, :roles_permissions)
#      |> assign(:permissions_by_category, permissions_by_category)
#      |> assign(:roles, roles)
#      |> assign(:active_tab, :permissions)
#      |> assign_selected(selected)}
#   end

#   @impl true
#   def handle_event("select_role", %{"id" => id}, socket) do
#     role = Enum.find(socket.assigns.roles, &(&1.id == String.to_integer(id)))
#     {:noreply, socket |> assign(:active_tab, :permissions) |> assign_selected(role)}
#   end

#   def handle_event("switch_tab", %{"tab" => tab}, socket) do
#     {:noreply, assign(socket, :active_tab, String.to_existing_atom(tab))}
#   end

#   def handle_event("toggle_permission", %{"category" => category, "action" => action}, socket) do
#     updated_role = Roles.toggle_role_permission(socket.assigns.selected_role, category, action)

#     roles =
#       Enum.map(socket.assigns.roles, fn
#         r when r.id == updated_role.id -> updated_role
#         r -> r
#       end)

#     {:noreply, socket |> assign(:roles, roles) |> assign_selected(updated_role)}
#   end

#   defp assign_selected(socket, role) do
#     view = build_permission_view(role, socket.assigns.permissions_by_category)

#     socket
#     |> assign(:selected_role, role)
#     |> assign(:selected_permission_view, view)
#     |> assign(:selected_user_count, length(role.role_assignments))
#     |> assign(:selected_assigned_users, Enum.map(role.role_assignments, & &1.user))
#   end

#   defp build_permission_view(role, permissions_by_category) do
#     granted = MapSet.new(role.permissions, &{&1.category, &1.action})

#     Map.new(permissions_by_category, fn {category, permissions} ->
#       actions =
#         Enum.map(permissions, fn p ->
#           {p.action, MapSet.member?(granted, {category, p.action})}
#         end)

#       {category, actions}
#     end)
#   end
# end
