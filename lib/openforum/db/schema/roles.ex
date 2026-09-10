defmodule OpenforumWeb.Schema.Role do
  use Ecto.Schema
  import Ecto.Changeset

  alias OpenforumWeb.Schema.{Permission, RolePermission, RoleAssignment}
  alias Openforum.Accounts.User

  schema "roles" do
    field :name, :string
    field :slug, :string
    field :description, :string
    field :is_active, :boolean, default: true

    many_to_many :permissions, Permission, join_through: RolePermission
    has_many :role_assignments, RoleAssignment
    many_to_many :users, User, join_through: RoleAssignment

    timestamps()
  end

  def changeset(role, attrs) do
    role
    |> cast(attrs, [:name, :description, :slug, :is_active])
    |> validate_required([:name, :description])
    |> maybe_put_slug()
    |> unique_constraint(:name)
    |> unique_constraint(:slug)
  end

  defp maybe_put_slug(changeset) do
    case get_field(changeset, :slug) do
      nil ->
        case get_change(changeset, :name) do
          nil -> changeset
          name -> put_change(changeset, :slug, slugify(name))
        end

      _ ->
        changeset
    end
  end

  defp slugify(name) do
    name
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "-")
    |> String.trim("-")
  end
end
