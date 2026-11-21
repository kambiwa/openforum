defmodule Openforum.Schema.MediaResource do
  use Ecto.Schema
  import Ecto.Changeset

  @media_types ~w(video audio presentation document)
  @statuses ~w(document published)

  schema "media_resources" do
    field :title, :string
    field :media_type, :string, default: "video"
    field :description, :string
    field :file_url, :string
    field :thumbnail_url, :string
    field :duration_seconds, :integer
    field :status, :string, default: "document"

    belongs_to :category, Openforum.Schema.ContentCategory
    belongs_to :uploaded_by, Openforum.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def media_types, do: @media_types
  def statuses, do: @statuses

  def changeset(resource, attrs) do
    resource
    |> cast(attrs, [
      :title,
      :media_type,
      :category_id,
      :description,
      :file_url,
      :thumbnail_url,
      :duration_seconds,
      :status
    ])
    |> validate_required([:title, :media_type, :file_url, :status])
    |> validate_length(:title, max: 200)
    |> validate_inclusion(:media_type, @media_types)
    |> validate_inclusion(:status, @statuses)
    |> validate_number(:duration_seconds, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:category_id)
  end
end
