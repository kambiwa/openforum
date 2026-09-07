defmodule OpenforumWeb.Schema.RoleAssignment do
  use Ecto.Schema
  import Ecto.Changeset

  alias OpenforumWeb.Schema.Role
  # alias to your actual user schema
  alias OpenforumWeb.Schema.User

  schema "role_assignments" do
    belongs_to :role, Role
    belongs_to :user, User

    timestamps()
  end

  def changeset(role_assignment, attrs) do
    role_assignment
    |> cast(attrs, [:role_id, :user_id])
    |> validate_required([:role_id, :user_id])
    |> unique_constraint([:role_id, :user_id])
  end
end
