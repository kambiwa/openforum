defmodule OpenforumWeb.Schema.UserWorkingAreaMembership do
  use Ecto.Schema
  import Ecto.Changeset

  alias Openforum.Accounts.User
  alias OpenforumWeb.Schema.WorkingArea

  @statuses ~w(active inactive)

  schema "user_working_area_memberships" do
    field :status, :string, default: "active"
    field :starts_on, :date
    field :ends_on, :date

    belongs_to :user, User
    belongs_to :working_area, WorkingArea

    timestamps(type: :utc_datetime)
  end

  def statuses, do: @statuses

  def changeset(membership, attrs) do
    membership
    |> cast(attrs, [:user_id, :working_area_id, :status, :starts_on, :ends_on])
    |> validate_required([:user_id, :working_area_id, :status, :starts_on])
    |> validate_inclusion(:status, @statuses)
    |> validate_date_range()
    |> unique_constraint([:user_id, :working_area_id],
      name: :user_working_area_memberships_active_user_area_index
    )
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:working_area_id)
  end

  defp validate_date_range(changeset) do
    starts_on = get_field(changeset, :starts_on)
    ends_on = get_field(changeset, :ends_on)

    if starts_on && ends_on && Date.compare(ends_on, starts_on) == :lt do
      add_error(changeset, :ends_on, "must be on or after the start date")
    else
      changeset
    end
  end
end
