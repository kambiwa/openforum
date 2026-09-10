defmodule Openforum.Schema.ContentItem do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(draft in_review approved published rejected)

  schema "content_items" do
    field :title, :string
    field :slug, :string
    field :summary, :string
    field :body, :string
    field :duration_label, :string
    field :status, :string, default: "draft"
    field :published_at, :utc_datetime

    belongs_to :category, Openforum.ContentCategory
    belongs_to :work_flow, Openforum.WorkFlow, foreign_key: :workflow_id
    belongs_to :current_step, Openforum.WorkFlowStep
    belongs_to :author, Openforum.Accounts.User
    has_many :content_attachments, Openforum.Schema.ContentAttachment

    timestamps(type: :utc_datetime)
  end

  def statuses, do: @statuses

  # Used before we know the resolved workflow/step — those get set
  # separately in Drafts.create_draft/2 once the category's default
  # workflow has been resolved.
  def create_changeset(content_item, attrs) do
    content_item
    |> cast(attrs, [:title, :summary, :body, :duration_label, :category_id])
    |> validate_required([:title, :body, :category_id])
    |> validate_length(:title, min: 1, max: 200)
    |> sanitize_body()
    |> put_slug()
    |> foreign_key_constraint(:category_id)
  end

  def update_changeset(content_item, attrs) do
    content_item
    |> cast(attrs, [:title, :summary, :body, :duration_label])
    |> validate_required([:title, :body])
    |> validate_length(:title, min: 1, max: 200)
    |> sanitize_body()
  end

  # Sanitize on save, not just on render — the WYSIWYG toolbar is limited
  # but nothing stops a pasted <script>/<iframe> from arriving in the
  # POST body regardless of what the toolbar exposes.
  defp sanitize_body(changeset) do
    update_change(changeset, :body, fn
      nil -> nil
      html -> HtmlSanitizeEx.basic_html(html)
    end)
  end

  defp put_slug(changeset) do
    case get_change(changeset, :title) do
      nil -> changeset
      title -> put_change(changeset, :slug, slugify(title))
    end
  end

  defp slugify(title) do
    base =
      title
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9\s-]/, "")
      |> String.trim()
      |> String.replace(~r/\s+/, "-")

    "#{base}-#{Ecto.UUID.generate() |> String.slice(0, 8)}"
  end
end
