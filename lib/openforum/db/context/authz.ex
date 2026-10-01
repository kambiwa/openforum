defmodule Openforum.Context.Authz do
  @moduledoc """
  Role/permission checks against the RBAC tables:

      User -> RoleAssignment -> Role -> RolePermission -> Permission{category, action}

  `category` matches the content-area labels shown in the Roles & Permissions
  admin UI (e.g. "Bible Content", "Catechism", "Doctrine Articles", "Media"),
  and `action` matches the toggle buttons ("Create", "Edit", "Delete",
  "Publish", "View", "Approve", "Reject").

  This context owns nothing but authorization logic — it has no knowledge of
  ContentItem, documents, or any other schema — so any context can depend on it
  without creating a reverse dependency.
  """

  import Ecto.Query, warn: false

  alias Openforum.Repo
  alias OpenforumWeb.Schema.{Role, Permission, RolePermission, RoleAssignment}

  @doc """
  Does `user` hold ANY role granting `{category, action}`?

  Category/action comparison is case-insensitive so a typo in casing when
  seeding roles (e.g. "view" vs "View") doesn't silently break access.
  """
  def has_permission?(user, category, action)

  def has_permission?(nil, _category, _action), do: false

  def has_permission?(user, category, action) do
    base_permission_query(user, category, action)
    |> Repo.exists?()
  end

  @doc """
  Does `user` hold ANY of the given `{category, action}` pairs?
  Useful when a single action is satisfied by more than one label
  (e.g. "Edit" or "Approve" both count as "can act on this").
  """
  def has_any_permission?(user, pairs) when is_list(pairs) do
    Enum.any?(pairs, fn {category, action} -> has_permission?(user, category, action) end)
  end

  @doc "Does `user` hold this exact role, by role id?"
  def has_role?(user, role_id)

  def has_role?(nil, _role_id), do: false
  def has_role?(_user, nil), do: false

  def has_role?(user, role_id) do
    from(ra in RoleAssignment,
      where: ra.user_id == ^user.id and ra.role_id == ^role_id
    )
    |> Repo.exists?()
  end

  @doc "Does `user` hold a role with this slug (e.g. \"apostle\", \"district-rector\")?"
  def has_role_by_slug?(nil, _slug), do: false

  def has_role_by_slug?(user, slug) do
    from(ra in RoleAssignment,
      join: r in Role, on: r.id == ra.role_id,
      where: ra.user_id == ^user.id and r.slug == ^slug and r.is_active == true
    )
    |> Repo.exists?()
  end

  @doc """
  Every {category, action} pair `user` is granted, across all of their
  active roles. Useful for building UI (e.g. hiding buttons the user can't
  use) without firing a query per button.
  """
  def list_user_permissions(nil), do: []

  def list_user_permissions(user) do
    from(ra in RoleAssignment,
      join: r in Role, on: r.id == ra.role_id and r.is_active == true,
      join: rp in RolePermission, on: rp.role_id == r.id,
      join: p in Permission, on: p.id == rp.permission_id,
      where: ra.user_id == ^user.id,
      distinct: true,
      select: {p.category, p.action}
    )
    |> Repo.all()
  end

  @doc "Every active role `user` holds."
  def list_user_roles(nil), do: []

  def list_user_roles(user) do
    from(r in Role,
      join: ra in RoleAssignment, on: ra.role_id == r.id,
      where: ra.user_id == ^user.id and r.is_active == true,
      order_by: r.name
    )
    |> Repo.all()
  end

  @doc """
  Every category name `user` holds `action` for — e.g. for filtering a
  content list down to categories the user is allowed to `"View"`.
  """
  def permitted_categories(nil, _action), do: []

  def permitted_categories(user, action) do
    from(ra in RoleAssignment,
      join: r in Role, on: r.id == ra.role_id and r.is_active == true,
      join: rp in RolePermission, on: rp.role_id == r.id,
      join: p in Permission, on: p.id == rp.permission_id,
      where: ra.user_id == ^user.id and ilike(p.action, ^action),
      distinct: true,
      select: p.category
    )
    |> Repo.all()
  end

  @doc """
  Raises `Openforum.NotAuthorizedError` unless `user` holds `{category, action}`.
  Returns `:ok` on success, for piping in a `with` chain.
  """
  def require_permission!(user, category, action) do
    if has_permission?(user, category, action) do
      :ok
    else
      raise Openforum.NotAuthorizedError,
        message: "missing permission #{inspect(category)}/#{inspect(action)}"
    end
  end

  # ── Private ──────────────────────────────────────────────────────────

  defp base_permission_query(user, category, action) do
    from(ra in RoleAssignment,
      join: r in Role, on: r.id == ra.role_id and r.is_active == true,
      join: rp in RolePermission, on: rp.role_id == r.id,
      join: p in Permission, on: p.id == rp.permission_id,
      where:
        ra.user_id == ^user.id and
          ilike(p.category, ^category) and
          ilike(p.action, ^action)
    )
  end
end
