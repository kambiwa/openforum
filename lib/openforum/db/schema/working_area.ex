defmodule OpenforumWeb.Schema.WorkingArea do
  use Ecto.Schema
  import Ecto.Changeset

  schema "working_area" do
    field :name, :string
    field :description, :string

    has_one :area_lead, OpenforumWeb.Schema.AreaLead
    timestamps()
  end

  @doc false
  def changeset(working_area, attrs) do
    working_area
    |> cast(attrs, [:name, :area_lead, :description])
    |> validate_required([:name])
  end
end
