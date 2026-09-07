defmodule OpenforumWeb.Schema.RolePermission do
  use Ecto.Schema
  import Ecto.Changeset

  alias OpenforumWeb.Schema.{Role, Permission}

  schema "role_permissions" do
    belongs_to :role, Role
    belongs_to :permission, Permission

    timestamps()
  end

  def changeset(role_permission, attrs) do
    role_permission
    |> cast(attrs, [:role_id, :permission_id])
    |> validate_required([:role_id, :permission_id])
    |> unique_constraint([:role_id, :permission_id])
  end
end
