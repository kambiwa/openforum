defmodule OpenForumWeb.Schema.Ministry do
  use Ecto.Schema
  import Ecto.Changeset

  schema "ministry" do
    field :title, :string
    field :is_active, :boolean, default: true
    has_many :approval_work_flow, OpenForumWeb.Schema.ApprovalWorkFlow
    has_one :working_area, OpenForumWeb.Schema.WorkingArea

    timestamps(
      type: :naive_datetime,
      autogenerate: {OpenForumWeb.LocalTimestamp, :autogenerate, []}
    )
  end

  @doc false
  def changeset(ministry, attrs) do
    ministry
    |> cast(attrs, [:title, :is_active])
    |> validate_inclusion(:title, ["Deacon", "Priest", "Apostle", "Bishop", "District Apostle"])
    |> validate_required([:title])
  end
end
