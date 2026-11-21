defmodule Openforum.Repo.Migrations.AddWorkingAreaHierarchyAndUserMemberships do
  use Ecto.Migration

  def change do
    alter table(:working_area) do
      add :parent_id, references(:working_area, on_delete: :restrict)
      add :is_active, :boolean, null: false, default: true
      add :order_index, :integer, null: false, default: 0
    end

    create index(:working_area, [:parent_id])
    create index(:working_area, [:is_active, :order_index])

    create constraint(:working_area, :working_area_order_must_be_nonnegative,
             check: "order_index >= 0"
           )

    create constraint(:working_area, :working_area_parent_not_self,
             check: "parent_id IS NULL OR parent_id <> id"
           )

    create table(:user_working_area_memberships) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :working_area_id, references(:working_area, on_delete: :restrict), null: false
      add :status, :string, null: false, default: "active"
      add :starts_on, :date, null: false, default: fragment("CURRENT_DATE")
      add :ends_on, :date

      timestamps(type: :utc_datetime)
    end

    create unique_index(:user_working_area_memberships, [:user_id, :working_area_id],
             where: "status = 'active'",
             name: :user_working_area_memberships_active_user_area_index
           )

    create index(:user_working_area_memberships, [:working_area_id, :status])
    create index(:user_working_area_memberships, [:user_id, :status])

    create constraint(:user_working_area_memberships, :membership_status_must_be_valid,
             check: "status IN ('active','inactive')"
           )

    create constraint(:user_working_area_memberships, :membership_dates_must_be_valid,
             check: "ends_on IS NULL OR ends_on >= starts_on"
           )

    execute(
      """
      INSERT INTO user_working_area_memberships
        (user_id, working_area_id, status, starts_on, inserted_at, updated_at)
      SELECT id, working_area_id, 'active', CURRENT_DATE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      FROM users
      WHERE working_area_id IS NOT NULL
      ON CONFLICT DO NOTHING
      """,
      "SELECT 1"
    )
  end
end
