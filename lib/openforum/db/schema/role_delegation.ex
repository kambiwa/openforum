defmodule Openforum.RoleDelegation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "role_delegations" do
    belongs_to :user, Openforum.Accounts.User
    belongs_to :role, Openforum.Role
    belongs_to :delegate_user, Openforum.Accounts.User

    field :starts_at, :utc_datetime
    field :ends_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(delegation, attrs) do
    delegation
    |> cast(attrs, [:user_id, :role_id, :delegate_user_id, :starts_at, :ends_at])
    |> validate_required([:user_id, :role_id, :delegate_user_id, :starts_at, :ends_at])
    |> validate_delegate_not_self()
    |> validate_end_after_start()
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:role_id)
    |> foreign_key_constraint(:delegate_user_id)
  end

  defp validate_delegate_not_self(changeset) do
    user_id = get_field(changeset, :user_id)
    delegate_id = get_field(changeset, :delegate_user_id)

    if user_id && delegate_id && user_id == delegate_id do
      add_error(changeset, :delegate_user_id, "cannot be the same as the user")
    else
      changeset
    end
  end

  defp validate_end_after_start(changeset) do
    starts_at = get_field(changeset, :starts_at)
    ends_at = get_field(changeset, :ends_at)

    if starts_at && ends_at && DateTime.compare(ends_at, starts_at) != :gt do
      add_error(changeset, :ends_at, "must be after the start date")
    else
      changeset
    end
  end
end
