defmodule OpenforumWeb.Schema.Role do
  use Ecto.Schema
  import Ecto.Changeset

  alias OpenforumWeb.Schema.{Permission, RolePermission, RoleAssignment, User}

  schema "roles" do
    field :name, :string
    field :description, :string

    many_to_many :permissions, Permission, join_through: RolePermission
    has_many :role_assignments, RoleAssignment
    many_to_many :users, User, join_through: RoleAssignment

    timestamps()
  end

  def changeset(role, attrs) do
    role
    |> cast(attrs, [:name, :description])
    |> validate_required([:name, :description])
    |> unique_constraint(:name)
  end
end
