defmodule Openforum.Schema.ContentCategory do
  use Ecto.Schema
  import Ecto.Changeset

  schema "content_categories" do
    field :name, :string
    field :slug, :string
    field :icon, :string
    field :description, :string
    field :order_index, :integer, default: 0
    field :is_active, :boolean, default: true

    belongs_to :default_work_flow, Openforum.WorkFlow
    has_many :content_items, Openforum.ContentItem

    timestamps(type: :utc_datetime)
  end

  def changeset(category, attrs) do
    category
    |> cast(attrs, [:name, :slug, :icon, :description, :order_index, :is_active, :default_work_flow_id])
    |> validate_required([:name, :slug])
    |> unique_constraint(:slug)
    |> foreign_key_constraint(:default_work_flow_id)
  end
end
