defmodule OpenforumWeb.Auth.RolesPermissions.Index do
  use OpenforumWeb, :live_view

  alias Openforum.Context.Roles
  alias OpenforumWeb.Schema.Role

  @impl true
  def mount(_params, _session, socket) do
    permissions_by_category = Roles.list_permissions_by_category()
    roles = Roles.list_roles()
    selected = List.first(roles)

    {:ok,
     socket
     |> assign(:current_scope, "")
     |> assign(:mobile_menu_open, false)
     |> assign(:page_title, "Roles & Permissions")
     |> assign(:current_page, :roles_permissions)
     |> assign(:permissions_by_category, permissions_by_category)
     |> assign(:roles, roles)
     |> assign(:active_tab, :permissions)
     |> assign(:role_modal, nil)
     |> assign(:role_form, nil)
     |> assign(:assign_modal_open?, false)
     |> assign(:available_users, [])
     |> assign_selected(selected)}
  end

  # ── Selecting / tabs ─────────────────────────────────────────────────

  @impl true
  def handle_event("select_role", %{"id" => id}, socket) do
    role = Enum.find(socket.assigns.roles, &(&1.id == String.to_integer(id)))
    {:noreply, socket |> assign(:active_tab, :permissions) |> assign_selected(role)}
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_tab, String.to_existing_atom(tab))}
  end

  # ── Permission toggling ──────────────────────────────────────────────

  def handle_event("toggle_permission", %{"category" => category, "action" => action}, socket) do
    case Roles.toggle_role_permission(socket.assigns.selected_role, category, action) do
      {:ok, updated_role} ->
        {:noreply,
         socket
         |> replace_role_in_list(updated_role)
         |> assign_selected(updated_role)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not update that permission.")}

      updated_role ->
        # backward-compatible path if toggle_role_permission returns the role directly
        {:noreply,
         socket
         |> replace_role_in_list(updated_role)
         |> assign_selected(updated_role)}
    end
  end

  # ── Create / edit role modal ────────────────────────────────────────

  def handle_event("new_role", _params, socket) do
    changeset = Roles.change_role(%Role{})

    {:noreply,
     socket
     |> assign(:role_modal, :new)
     |> assign(:role_form, to_form(changeset))}
  end

  def handle_event("edit_role", _params, socket) do
    changeset = Roles.change_role(socket.assigns.selected_role)

    {:noreply,
     socket
     |> assign(:role_modal, :edit)
     |> assign(:role_form, to_form(changeset))}
  end

  def handle_event("cancel_role_modal", _params, socket) do
    {:noreply, socket |> assign(:role_modal, nil) |> assign(:role_form, nil)}
  end

  def handle_event("validate_role", %{"role" => params}, socket) do
    base =
      case socket.assigns.role_modal do
        :edit -> socket.assigns.selected_role
        _ -> %Role{}
      end

    changeset = base |> Roles.change_role(params) |> Map.put(:action, :validate)
    {:noreply, assign(socket, :role_form, to_form(changeset))}
  end

  def handle_event("save_role", %{"role" => params}, socket) do
    modal = socket.assigns.role_modal

    result =
      case modal do
        :edit -> Roles.update_role(socket.assigns.selected_role, params)
        _ -> Roles.create_role(params)
      end

    case result do
      {:ok, role} ->
        roles = Roles.list_roles()
        success_message = if modal == :edit, do: "Role updated successfully.", else: "Role created successfully."

        {:noreply,
         socket
         |> assign(:roles, roles)
         |> assign(:role_modal, nil)
         |> assign(:role_form, nil)
         |> assign_selected(role)
         |> put_flash(:info, success_message)}

      {:error, %Ecto.Changeset{} = changeset} ->
        error_message = if modal == :edit, do: "Could not update role.", else: "Could not create role."

        {:noreply,
         socket
         |> assign(:role_form, to_form(changeset))
         |> put_flash(:error, error_message)}
    end
  end

  # ── Delete role ──────────────────────────────────────────────────────

  def handle_event("delete_role", _params, socket) do
    case Roles.delete_role(socket.assigns.selected_role) do
      {:ok, _} ->
        roles = Roles.list_roles()

        {:noreply,
         socket
         |> assign(:roles, roles)
         |> assign(:active_tab, :permissions)
         |> assign_selected(List.first(roles))
         |> put_flash(:info, "Role deleted successfully.")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not delete this role.")}
    end
  end

  # ── Assign / remove users ───────────────────────────────────────────

  def handle_event("assign_user", _params, socket) do
    available_users = Roles.list_users_available_for_role(socket.assigns.selected_role)

    {:noreply,
     socket
     |> assign(:assign_modal_open?, true)
     |> assign(:available_users, available_users)}
  end

  def handle_event("cancel_assign_modal", _params, socket) do
    {:noreply, assign(socket, :assign_modal_open?, false)}
  end

  def handle_event("do_assign_user", %{"user-id" => user_id}, socket) do
    case Roles.assign_user(socket.assigns.selected_role, user_id) do
      {:ok, _} ->
        role = Roles.get_role!(socket.assigns.selected_role.id)

        {:noreply,
         socket
         |> replace_role_in_list(role)
         |> assign_selected(role)
         |> assign(:assign_modal_open?, false)
         |> put_flash(:info, "User assigned successfully.")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not assign that user.")}
    end
  end

  def handle_event("remove_user", %{"user-id" => user_id}, socket) do
    case Roles.remove_user(socket.assigns.selected_role, user_id) do
      {:ok, _} ->
        role = Roles.get_role!(socket.assigns.selected_role.id)

        {:noreply,
         socket
         |> replace_role_in_list(role)
         |> assign_selected(role)
         |> put_flash(:info, "User removed successfully.")}

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, "Could not remove that user.")}
    end
  end

  # ── Private ──────────────────────────────────────────────────────────

  defp assign_selected(socket, nil) do
    socket
    |> assign(:selected_role, nil)
    |> assign(:selected_permission_view, %{})
    |> assign(:selected_user_count, 0)
    |> assign(:selected_assigned_users, [])
  end

  defp assign_selected(socket, %Role{} = role) do
    view = Roles.permission_view_for(role, socket.assigns.permissions_by_category)

    socket
    |> assign(:selected_role, role)
    |> assign(:selected_permission_view, view)
    |> assign(:selected_user_count, length(role.role_assignments))
    |> assign(:selected_assigned_users, Enum.map(role.role_assignments, & &1.user))
  end

  defp replace_role_in_list(socket, %Role{} = updated_role) do
    roles =
      Enum.map(socket.assigns.roles, fn
        r when r.id == updated_role.id -> updated_role
        r -> r
      end)

    assign(socket, :roles, roles)
  end
end
