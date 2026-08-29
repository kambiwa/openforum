defmodule OpenForumWeb.Schema.AreaLead do
  use Ecto.Schema
  import Ecto.Changeset

  schema "area_lead" do
    field :name, :string
    field :description, :string

    has_one :working_area, OpenForumWeb.Schema.WorkingArea
    timestamps()
  end

  @doc false
  def changeset(area_lead, attrs) do
    area_lead
    |> cast(attrs, [:name, :working_area, :description])
    |> validate_required([:name])
  end
end
