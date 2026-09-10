defmodule OpenforumWeb.Schema.Permission do
  use Ecto.Schema
  import Ecto.Changeset

  alias OpenforumWeb.Schema.{Role, RolePermission}

    schema "permissions" do
    field :category, :string
    field :action, :string

    many_to_many :roles, Role, join_through: RolePermission

    timestamps(type: :utc_datetime)
  end

  def changeset(permission, attrs) do
    permission
    |> cast(attrs, [:category, :action])
    |> validate_required([:category, :action])
    |> unique_constraint([:category, :action], name: :permissions_category_action_index)
  end
end
