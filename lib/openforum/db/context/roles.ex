defmodule Openforum.Context.Roles do
  @moduledoc """
  Context for Roles, Permissions, and Role Assignments.
  """

  import Ecto.Query, warn: false

  alias Openforum.Repo
  alias OpenforumWeb.Schema.{Role, Permission, RolePermission, RoleAssignment}
  alias Openforum.Accounts.User

  # ── Roles ────────────────────────────────────────────────────────────

  def list_roles do
    Role
    |> preload([:permissions, role_assignments: :user])
    |> order_by([r], asc: r.name)
    |> Repo.all()
  end

  def get_role!(id) do
    Role
    |> preload([:permissions, role_assignments: :user])
    |> Repo.get!(id)
  end

  def create_role(attrs \\ %{}) do
    %Role{}
    |> Role.changeset(attrs)
    |> Repo.insert()
    |> reload_with_assocs()
  end

  def update_role(%Role{} = role, attrs) do
    role
    |> Role.changeset(attrs)
    |> Repo.update()
    |> reload_with_assocs()
  end

  def delete_role(%Role{} = role), do: Repo.delete(role)

  def change_role(%Role{} = role, attrs \\ %{}), do: Role.changeset(role, attrs)

  defp reload_with_assocs({:ok, %Role{} = role}), do: {:ok, get_role!(role.id)}
  defp reload_with_assocs(error), do: error

  # ── Permissions ──────────────────────────────────────────────────────

  @doc """
  All permissions, grouped by category, ordered for stable rendering.
  """
  def list_permissions_by_category do
    Permission
    |> order_by([p], asc: p.category, asc: p.action)
    |> Repo.all()
    |> Enum.group_by(& &1.category)
  end

  @doc """
  Toggle whether `role` has the given category/action permission.
  Presence of the RolePermission join row IS the "enabled" state.
  Returns the reloaded role (with fresh `:permissions` preload).
  """
  def toggle_role_permission(%Role{} = role, category, action) do
    permission = Repo.get_by!(Permission, category: category, action: action)

    case Repo.get_by(RolePermission, role_id: role.id, permission_id: permission.id) do
      nil ->
        %RolePermission{}
        |> RolePermission.changeset(%{role_id: role.id, permission_id: permission.id})
        |> Repo.insert()

      role_permission ->
        Repo.delete(role_permission)
    end

    get_role!(role.id)
  end

  @doc """
  Builds the {category => [{action, enabled?}]} view shape the template
  expects, from the full permission catalog + whatever the role currently
  has granted.
  """
  def permission_view_for(%Role{} = role, permissions_by_category) do
    granted = MapSet.new(role.permissions, &{&1.category, &1.action})

    Map.new(permissions_by_category, fn {category, permissions} ->
      actions =
        Enum.map(permissions, fn p ->
          {p.action, MapSet.member?(granted, {category, p.action})}
        end)

      {category, actions}
    end)
  end

  # ── Role Assignments ─────────────────────────────────────────────────

  def assign_user(%Role{} = role, user_id) do
    %RoleAssignment{}
    |> RoleAssignment.changeset(%{role_id: role.id, user_id: user_id})
    |> Repo.insert()
  end

  def remove_user(%Role{} = role, user_id) do
    case Repo.get_by(RoleAssignment, role_id: role.id, user_id: user_id) do
      nil -> {:error, :not_found}
      assignment -> Repo.delete(assignment)
    end
  end

  @doc """
  Users not already assigned to `role`, for the "Assign Another User" picker.
  """
  def list_users_available_for_role(%Role{} = role) do
    assigned_ids =
      RoleAssignment
      |> where([ra], ra.role_id == ^role.id)
      |> select([ra], ra.user_id)
      |> Repo.all()

    User
    |> where([u], u.id not in ^assigned_ids)
    |> order_by([u], asc: u.first_name, asc: u.last_name)
    |> Repo.all()
  end
end
