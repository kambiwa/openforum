defmodule OpenforumWeb.Schema.AreaLead do
  use Ecto.Schema
  import Ecto.Changeset

  schema "area_lead" do
    field :name, :string
    field :description, :string

    has_one :working_area, OpenforumWeb.Schema.WorkingArea
    timestamps()
  end

  @doc false
  def changeset(area_lead, attrs) do
    area_lead
    |> cast(attrs, [:name, :description])
    |> validate_required([:name])
  end
end
