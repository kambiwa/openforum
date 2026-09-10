defmodule Openforum.Schema.ContentAttachment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "content_attachments" do
    field :file_type, :string
    field :file_url, :string
    field :caption, :string

    belongs_to :content_item, Openforum.ContentItem

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(attachment, attrs) do
    attachment
    |> cast(attrs, [:content_item_id, :file_type, :file_url, :caption])
    |> validate_required([:content_item_id, :file_type, :file_url])
    |> foreign_key_constraint(:content_item_id)
  end
end
