defmodule Openforum.Context.Roles do
  import Ecto.Query, warn: false

  alias OpenforumWeb.Repo
  alias OpenforumWeb.Schema.{Role, Permission, RolePermission, RoleAssignment}

  # ── Roles ──────────────────────────────────────────────────────────

  def list_roles do
    Role
    |> preload([:permissions, :role_assignments])
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
  end

  def update_role(%Role{} = role, attrs) do
    role
    |> Role.changeset(attrs)
    |> Repo.update()
  end

  def delete_role(%Role{} = role), do: Repo.delete(role)

  def change_role(%Role{} = role, attrs \\ %{}), do: Role.changeset(role, attrs)

  # ── Permissions ───────────────────────────────────────────────────

  @doc """
  Returns all permissions grouped by resource, e.g.
  %{"access_logs" => [%Permission{action: "view"}, ...]}
  """
  def list_permissions_grouped do
    Permission
    |> Repo.all()
    |> Enum.group_by(& &1.resource)
  end

  def enabled_permission_ids(%Role{} = role) do
    role.permissions
    |> Enum.map(& &1.id)
    |> MapSet.new()
  end

  @doc "Flips a role/permission pairing on or off."
  def toggle_role_permission(%Role{id: role_id}, %Permission{id: permission_id}) do
    case Repo.get_by(RolePermission, role_id: role_id, permission_id: permission_id) do
      nil ->
        %RolePermission{}
        |> RolePermission.changeset(%{role_id: role_id, permission_id: permission_id})
        |> Repo.insert()

      role_permission ->
        Repo.delete(role_permission)
    end
  end

  # ── Assignments ───────────────────────────────────────────────────

  def assign_user_to_role(role_id, user_id) do
    %RoleAssignment{}
    |> RoleAssignment.changeset(%{role_id: role_id, user_id: user_id})
    |> Repo.insert()
  end

  def remove_user_from_role(role_id, user_id) do
    case Repo.get_by(RoleAssignment, role_id: role_id, user_id: user_id) do
      nil -> {:error, :not_found}
      assignment -> Repo.delete(assignment)
    end
  end
end
