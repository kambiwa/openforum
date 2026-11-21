defmodule OpenforumWeb.Schema.WorkingArea do
  use Ecto.Schema
  import Ecto.Changeset

  alias OpenforumWeb.Schema.UserWorkingAreaMembership

  schema "working_area" do
    field :name, :string
    field :description, :string
    field :is_active, :boolean, default: true
    field :order_index, :integer, default: 0

    belongs_to :parent, __MODULE__, foreign_key: :parent_id
    has_many :children, __MODULE__, foreign_key: :parent_id

    has_one :area_lead, OpenforumWeb.Schema.AreaLead
    has_many :memberships, UserWorkingAreaMembership

    many_to_many :members, Openforum.Accounts.User,
      join_through: UserWorkingAreaMembership,
      join_keys: [working_area_id: :id, user_id: :id]

    timestamps()
  end

  @doc false
  def changeset(working_area, attrs) do
    working_area
    |> cast(attrs, [:name, :description, :parent_id, :is_active, :order_index])
    |> validate_required([:name, :is_active, :order_index])
    |> validate_length(:name, min: 1, max: 160)
    |> validate_number(:order_index, greater_than_or_equal_to: 0)
    |> validate_parent_not_self()
    |> foreign_key_constraint(:parent_id)
    |> check_constraint(:parent_id, name: :working_area_parent_not_self)
    |> check_constraint(:order_index, name: :working_area_order_must_be_nonnegative)
    |> unique_constraint(:name)
  end

  defp validate_parent_not_self(changeset) do
    if get_field(changeset, :id) && get_field(changeset, :id) == get_field(changeset, :parent_id) do
      add_error(changeset, :parent_id, "cannot be its own parent")
    else
      changeset
    end
  end
end
