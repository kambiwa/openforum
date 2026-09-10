defmodule OpenforumWeb.Schema.RoleAssignment do
  use Ecto.Schema
  import Ecto.Changeset

  alias OpenforumWeb.Schema.Role
  alias Openforum.Accounts.User

  schema "role_assignments" do
    belongs_to :role, Role
    belongs_to :user, User

    timestamps()
  end

  def changeset(role_assignment, attrs) do
    role_assignment
    |> cast(attrs, [:role_id, :user_id])
    |> validate_required([:role_id, :user_id])
    |> unique_constraint([:role_id, :user_id], name: :role_assignments_role_id_user_id_index)
  end
end
