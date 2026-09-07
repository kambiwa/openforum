# lib/openforum_web/schema/permission.ex
defmodule OpenforumWeb.Schema.Permission do
  use Ecto.Schema
  import Ecto.Changeset

  schema "permissions" do
    field :resource, :string
    field :action, :string

    timestamps()
  end

  def changeset(permission, attrs) do
    permission
    |> cast(attrs, [:resource, :action])
    |> validate_required([:resource, :action])
    |> unique_constraint([:resource, :action])
  end
end
