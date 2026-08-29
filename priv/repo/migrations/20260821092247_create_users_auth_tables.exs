defmodule Openforum.Repo.Migrations.CreateOpenforumTables do
  use Ecto.Migration

  def change do
    # ============================================================
    # CITEXT
    # ============================================================
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

     

    # ============================================================
    # WORKING AREA
    # ============================================================
    # congregation, district rector area, apostle area, etc.
    create table(:working_area) do
      add :name, :string, null: false
      add :description, :string

      timestamps()
    end

    create unique_index(:working_area, [:name])

    # ============================================================
    # AREA LEAD
    # ============================================================
    # WorkingArea has_one :area_lead -> FK lives here.
    create table(:area_lead) do
      add :working_area_id,
          references(:working_area, on_delete: :nilify_all)

      add :name, :string
      add :description, :string

      timestamps()
    end

    create unique_index(:area_lead, [:working_area_id])

    # ============================================================
    # USERS
    # ============================================================
    create table(:users) do
      add :first_name, :string
      add :last_name, :string
      add :email, :string
      add :hashed_password, :string
      add :confirmed_at, :utc_datetime
      add :working_area_id, references(:working_area, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:users, [:working_area_id])
    create unique_index(:users, [:email])

    # ============================================================
    # USER TOKENS
    # ============================================================
    create table(:users_tokens) do
      add :user_id,
          references(:users, on_delete: :delete_all),
          null: false

      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string
      add :authenticated_at, :utc_datetime

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:users_tokens, [:user_id])
    create unique_index(:users_tokens, [:context, :token])

    # ============================================================
    # ROLES
    # ============================================================
    create table(:roles) do
      add :name, :string, null: false
      add :slug, :string, null: false
      add :description, :string
      add :is_active, :boolean, null: false, default: true

      timestamps(type: :utc_datetime)
    end

    create unique_index(:roles, [:slug])

    # ============================================================
    # USER ROLES
    # ============================================================
    create table(:user_roles) do
      add :user_id,
          references(:users, on_delete: :delete_all),
          null: false

      add :role_id,
          references(:roles, on_delete: :delete_all),
          null: false

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create unique_index(:user_roles, [:user_id, :role_id])

    # ============================================================
    # APPROVAL LEVELS
    # ============================================================
    create table(:approval_levels) do
      add :name, :string, null: false
      add :slug, :string, null: false
      add :order_index, :integer, null: false

      add :role_id,
          references(:roles, on_delete: :nilify_all)

      add :description, :string
      add :is_active, :boolean, null: false, default: true

      timestamps(type: :utc_datetime)
    end

    create unique_index(:approval_levels, [:slug])
    create index(:approval_levels, [:order_index])

    # ============================================================
    # WORKFLOWS
    # ============================================================
    create table(:workflows) do
      add :name, :string, null: false
      add :status, :string, null: false, default: "active"

      add :flow,
          {:array, :map},
          null: false,
          default: []

      add :description, :string
      add :is_active, :boolean, null: false, default: true

      timestamps(type: :utc_datetime)
    end

    # ============================================================
    # CONTENT CATEGORIES
    # ============================================================
    create table(:content_categories) do
      add :name, :string, null: false
      add :slug, :string, null: false
      add :icon, :string
      add :description, :string
      add :order_index, :integer, null: false, default: 0
      add :is_active, :boolean, null: false, default: true

      timestamps(type: :utc_datetime)
    end

    create unique_index(:content_categories, [:slug])

    # ============================================================
    # CONTENT ITEMS
    # ============================================================
    create table(:content_items) do
      add :title, :string, null: false
      add :slug, :string, null: false
      add :summary, :string
      add :body, :text
      add :duration_label, :string

      add :status, :string, null: false, default: "draft"

      add :category_id,
          references(:content_categories, on_delete: :restrict),
          null: false

      add :workflow_id,
          references(:workflows, on_delete: :nilify_all)

      add :current_approval_level_id,
          references(:approval_levels, on_delete: :nilify_all)

      add :author_id,
          references(:users, on_delete: :nilify_all)

      add :published_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:content_items, [:slug])
    create index(:content_items, [:category_id])
    create index(:content_items, [:status])
    create index(:content_items, [:author_id])

    # ============================================================
    # CONTENT APPROVALS
    # ============================================================
    create table(:content_approvals) do
      add :content_item_id,
          references(:content_items, on_delete: :delete_all),
          null: false

      add :approval_level_id,
          references(:approval_levels, on_delete: :restrict),
          null: false

      add :reviewer_id,
          references(:users, on_delete: :nilify_all)

      add :action, :string, null: false
      add :comments, :text

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:content_approvals, [:content_item_id])
    create index(:content_approvals, [:approval_level_id])
    create index(:content_approvals, [:reviewer_id])

    # ============================================================
    # CONTENT ATTACHMENTS
    # ============================================================
    create table(:content_attachments) do
      add :content_item_id,
          references(:content_items, on_delete: :delete_all),
          null: false

      add :file_type, :string, null: false
      add :file_url, :string, null: false
      add :caption, :string

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:content_attachments, [:content_item_id])

    # ============================================================
    # MEDIA RESOURCES
    # ============================================================
    create table(:media_resources) do
      add :title, :string, null: false
      add :media_type, :string, null: false

      add :category_id,
          references(:content_categories, on_delete: :nilify_all)

      add :description, :text
      add :file_url, :string, null: false
      add :thumbnail_url, :string
      add :duration_seconds, :integer

      add :status, :string, null: false, default: "draft"

      add :uploaded_by_id,
          references(:users, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:media_resources, [:category_id])
    create index(:media_resources, [:media_type])
    create index(:media_resources, [:status])
    create index(:media_resources, [:uploaded_by_id])

    # ============================================================
    # NOTIFICATIONS
    # ============================================================
    create table(:notifications) do
      add :status, :string
      add :type, :string
      add :message, :string
      add :read, :boolean, null: false, default: false
      add :action_url, :string
      add :sender_name, :string
      add :document_name, :string
      add :document_id, :string
      add :comments, :string

      add :user_id,
          references(:users, on_delete: :delete_all),
          null: false

      add :sender_id,
          references(:users, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:notifications, [:user_id])
    create index(:notifications, [:read])
    create index(:notifications, [:sender_id])
  end
end
