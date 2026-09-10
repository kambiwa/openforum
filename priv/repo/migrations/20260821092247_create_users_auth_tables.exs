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
    # ROLES, PERMISSIONS
    # ============================================================
    create table(:roles) do
      add :name, :string, null: false
      add :slug, :string, null: false
      add :description, :string
      add :is_active, :boolean, null: false, default: true

      timestamps(type: :utc_datetime)
    end

    create unique_index(:roles, [:slug])


    create table(:permissions) do
      add :category, :string, null: false
      add :action, :string, null: false
      timestamps(type: :utc_datetime)
    end
    create unique_index(:permissions, [:category, :action])


    create table(:role_permissions) do
      add :role_id, references(:roles, on_delete: :delete_all), null: false
      add :permission_id, references(:permissions, on_delete: :delete_all), null: false
      timestamps(type: :utc_datetime)
    end
    create unique_index(:role_permissions, [:role_id, :permission_id])


    create table(:role_assignments) do
      add :role_id, references(:roles, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      timestamps(type: :utc_datetime)
    end
    create unique_index(:role_assignments, [:role_id, :user_id])


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
    # ROLE DELEGATIONS
    # ============================================================
    # "I'm out of office" — user_id temporarily delegates acting
    # authority for role_id to delegate_user_id, for a time window.
    # General across all workflows (not per-step).
    create table(:role_delegations) do
      add :user_id,
          references(:users, on_delete: :delete_all),
          null: false

      add :role_id,
          references(:roles, on_delete: :delete_all),
          null: false

      add :delegate_user_id,
          references(:users, on_delete: :delete_all),
          null: false

      add :starts_at, :utc_datetime, null: false
      add :ends_at, :utc_datetime, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:role_delegations, [:user_id])
    create index(:role_delegations, [:role_id])
    create index(:role_delegations, [:delegate_user_id])


    # ============================================================
    # WORK FLOWS
    # ============================================================
    create table(:work_flows) do
      add :name, :string, null: false
      add :status, :string, null: false, default: "active"
      add :description, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:work_flows, [:name])
    create index(:work_flows, [:status])


        # ============================================================
    # WORK FLOW STEPS
    # ============================================================
    # The ordered approval ladder for a workflow. Any user holding
    # role_id can act on a step; delegation (out-of-office) is
    # handled separately via role_delegations, not per-step.
    #
    # stage_type groups steps into the three phases of the ladder
    # (draft / reviewer / approver) and drives order_index — order
    # is computed by the app (stage first, then creation order
    # within a stage), not manually reordered.
    create table(:work_flow_steps) do
      add :work_flow_id,
          references(:work_flows, on_delete: :delete_all),
          null: false

      add :name, :string, null: false
      add :description, :string
      add :action, :string
      add :stage_type, :string, null: false, default: "draft"

      add :role_id,
          references(:roles, on_delete: :restrict),
          null: false

      add :order_index, :integer, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:work_flow_steps, [:work_flow_id])
    create index(:work_flow_steps, [:role_id])
    create unique_index(:work_flow_steps, [:work_flow_id, :order_index])

    create constraint(:work_flow_steps, :stage_type_must_be_valid,
             check: "stage_type IN ('draft','reviewer','approver')"
           )


    # ============================================================
    # CONTENT CATEGORIES
    # ============================================================
    # Landing page categories:
    #
    # Bible
    # Doctrine
    # Catechism
    # Questions & Answers
    # Media
    #
    create table(:content_categories) do
      add :name, :string, null: false
      add :slug, :string, null: false
      add :icon, :string
      add :description, :string
      add :order_index, :integer, null: false, default: 0
      add :is_active, :boolean, null: false, default: true
      add :default_work_flow_id, references(:work_flows, on_delete: :nilify_all)


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
          references(:work_flows, on_delete: :nilify_all)

      add :current_step_id,
          references(:work_flow_steps, on_delete: :nilify_all)

      add :author_id,
          references(:users, on_delete: :nilify_all)

      add :published_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:content_items, [:slug])
    create index(:content_items, [:category_id])
    create index(:content_items, [:status])
    create index(:content_items, [:author_id])
    create index(:content_items, [:workflow_id])
    create index(:content_items, [:current_step_id])


    # ============================================================
    # WORK FLOW STEP ACTIONS
    # ============================================================
    # Audit trail: every approve/reject on a content item at a
    # given step. actor_id is who actually acted; acted_as_role_id
    # records whether they acted under their own role or as a
    # delegate (see role_delegations). Comments are mandatory.
    create table(:work_flow_step_actions) do
      add :content_item_id,
          references(:content_items, on_delete: :delete_all),
          null: false

      add :work_flow_step_id,
          references(:work_flow_steps, on_delete: :restrict),
          null: false

      add :actor_id,
          references(:users, on_delete: :nilify_all)

      add :acted_as_role_id,
          references(:roles, on_delete: :nilify_all)

      add :action, :string, null: false
      add :comments, :text, null: false

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:work_flow_step_actions, [:content_item_id])
    create index(:work_flow_step_actions, [:work_flow_step_id])
    create index(:work_flow_step_actions, [:actor_id])


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
