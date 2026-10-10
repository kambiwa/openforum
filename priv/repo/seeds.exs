# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Or rebuild everything from scratch (drop, create, migrate, seed):
#
#     mix ecto.reset
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Openforum.Repo.insert!(%Openforum.SomeSchema{})
#


alias Openforum.Repo
alias Openforum.Accounts
alias Openforum.Accounts.User
alias OpenforumWeb.Schema.{Permission, Role, RolePermission, RoleAssignment}
alias Openforum.Schema.ContentCategory
alias Openforum.Schema.WorkFlow
alias Openforum.Schema.WorkFlowStep

import Ecto.Query

# ── 0. Users ─────────────────────────────────────────────────────────
#
# Registers the users referenced in the role-assignment section below,
# and confirms them immediately so they can log in right away in dev.

users_attrs = [
  %{first_name: "grey", last_name: "luka", email: "dev@dev.com", password: "dev@dev.com"},
  %{first_name: "green", last_name: "Mulenga", email: "green@dev.com", password: "dev@dev.com"},
  %{first_name: "brown", last_name: "lubasi", email: "brown@dev.com", password: "dev@dev.com"},
  %{first_name: "White", last_name: "Kakoma", email: "white@dev.com", password: "dev@dev.com"},
  %{first_name: "Black", last_name: "Sepo", email: "black@dev.com", password: "admin@dev.com"}
]

users =
  for attrs <- users_attrs do
    case Accounts.get_user_by_email(attrs.email) do
      nil ->
        {:ok, user} = Accounts.register_user(attrs)
        user |> User.confirm_changeset() |> Repo.update!()

      %User{} = user ->
        user
    end
  end

IO.puts("Seeded #{length(users)} users.")

# ── 1. Permissions (category/action pairs) ─────────────────────────────

categories = %{
  "Bible Content" => ~w(View Create Edit Publish Delete),
  "Doctrine Articles" => ~w(View Create Edit Publish Delete),
  "Catechism" => ~w(View Create Edit Publish Delete),
  "Approval Queue" => ~w(View Create Edit Approve Reject),
  "Media" => ~w(View Create Edit Publish Delete),
  "Q&A" => ~w(View Create Edit Publish Delete)
}

permissions =
  for {category, actions} <- categories, action <- actions do
    Repo.insert!(
      %Permission{category: category, action: action},
      on_conflict: {:replace, [:updated_at]},
      conflict_target: [:category, :action],
      returning: true
    )
  end

permission_by_key = Map.new(permissions, &{{&1.category, &1.action}, &1})

# ── 2. Roles ─────────────────────────────────────────────────────────

roles_attrs = [
   %{
    name: "District Apostle",
    slug: "district-apostle",
    description: "Final sign-off, approves stage 6 (District Apostle Area)",
    granted: [
      {"Bible Content", "View"}, {"Bible Content", "Publish"},
      {"Doctrine Articles", "View"}, {"Doctrine Articles", "Publish"},
      {"Catechism", "View"}, {"Catechism", "Publish"},
      {"Approval Queue", "View"}, {"Approval Queue", "Approve"}, {"Approval Queue", "Reject"}
    ]
  },
  %{
    name: "Lead Apostle",
    slug: "lead-apostle",
    description: "Final sign-off, approves stage 5 (Lead Apostle Area)",
    granted: [
      {"Bible Content", "View"}, {"Bible Content", "Publish"},
      {"Doctrine Articles", "View"}, {"Doctrine Articles", "Publish"},
      {"Catechism", "View"}, {"Catechism", "Publish"},
      {"Approval Queue", "View"}, {"Approval Queue", "Approve"}, {"Approval Queue", "Reject"}
    ]
  },
    %{
    name: "Apostle",
    slug: "apostle",
    description: "Final sign-off, Performs doctrinal review, approves stage 4 (Apostle Area)",
    granted: [
      {"Bible Content", "View"},
      {"Doctrine Articles", "View"}, {"Doctrine Articles", "Edit"},
      {"Catechism", "View"},
      {"Approval Queue", "View"}, {"Approval Queue", "Approve"}, {"Approval Queue", "Reject"}
    ]
  },
    %{
    name: "Bishop",
    slug: "bishop",
    description: "Final sign-off, Reviews submitted content and approves stage 3 (Apostle Area)",
    granted: [
      {"Bible Content", "View"}, {"Bible Content", "Create"}, {"Bible Content", "Edit"},
      {"Doctrine Articles", "View"}, {"Doctrine Articles", "Create"}, {"Doctrine Articles", "Edit"},
      {"Catechism", "View"}, {"Catechism", "Create"}, {"Catechism", "Edit"},
      {"Approval Queue", "View"}
    ]
  },
  %{
    name: "District Rector",
    slug: "district-rector",
    description: "Reviews submitted content and approves stage 2 (District Rector area)",
    granted: [
      {"Bible Content", "View"}, {"Bible Content", "Create"}, {"Bible Content", "Edit"},
      {"Doctrine Articles", "View"}, {"Doctrine Articles", "Create"}, {"Doctrine Articles", "Edit"},
      {"Catechism", "View"}, {"Catechism", "Create"}, {"Catechism", "Edit"},
      {"Approval Queue", "View"}
    ]
  },
  %{
    name: "Congregation Rector",
    slug: "congregation-rector",
    description: "submits for review 1 (Congregation)",
    granted: [
      {"Bible Content", "View"}, {"Bible Content", "Create"}, {"Bible Content", "Edit"},
      {"Doctrine Articles", "View"}, {"Doctrine Articles", "Create"}, {"Doctrine Articles", "Edit"},
      {"Catechism", "View"}, {"Catechism", "Create"}, {"Catechism", "Edit"},
      {"Approval Queue", "View"}
    ]
  },
  %{
    name: "Media Coordinator",
    slug: "media-coordinator",
    description: "Uploads and manages media assets across categories",
    granted: [
      {"Media", "View"}, {"Media", "Create"}, {"Media", "Edit"}, {"Media", "Publish"},
      {"Q&A", "View"}, {"Q&A", "Create"},
      {"Approval Queue", "View"}
    ]
  }
]

roles =
  Enum.map(roles_attrs, fn attrs ->
    role =
      Repo.insert!(
        %Role{
          name: attrs.name,
          slug: attrs.slug,
          description: attrs.description,
          is_active: true
        },
        on_conflict: {:replace, [:description, :is_active, :updated_at]},
        conflict_target: [:slug],
        returning: true
      )

    {role, attrs.granted}
  end)

# ── 3. Role ↔ Permission grants ─────────────────────────────────────

for {role, granted_keys} <- roles, key <- granted_keys do
  permission = Map.fetch!(permission_by_key, key)

  Repo.insert!(
    %RolePermission{role_id: role.id, permission_id: permission.id},
    on_conflict: :nothing,
    conflict_target: [:role_id, :permission_id]
  )
end

# ── 4. Role assignments ──────────────────────────────────────────────
#
# One role per seeded user, so every login has something to test with.

user_role_assignments = [
  {"yellow@dev.com", "congregation-rector"},
  {"blue@dev.com", "district-rector"},
  {"red@dev.com", "lead-apostle"},
  {"green@dev.com", "apostle"},
  {"brown@dev.com", "media-coordinator"},
  {"white@dev.com", "bishop"},
  {"black@dev.com", "district-apostle"}
]

for {email, role_slug} <- user_role_assignments do
  case {Repo.get_by(User, email: email), Repo.get_by(Role, slug: role_slug)} do
    {%User{} = user, %Role{} = role} ->
      Repo.insert!(
        %RoleAssignment{role_id: role.id, user_id: user.id},
        on_conflict: :nothing,
        conflict_target: [:role_id, :user_id]
      )

    _ ->
      IO.puts("Skipped role assignment for #{email} / #{role_slug} — user or role not found.")
  end
end

IO.puts("Seeded #{length(permissions)} permissions and #{length(roles)} roles.")

# ── 5. Content categories, workflow, and steps ──────────────────────
#
# Categories mirror the permission categories above (minus "Approval
# Queue", which isn't a content category — it's the review/approve
# action space). Slugs match what Document.Index/FormComponent expect.

content_categories_attrs = [
  %{name: "Bible Content", slug: "bible-content", order_index: 1},
  %{name: "Doctrine Articles", slug: "doctrine-articles", order_index: 2},
  %{name: "Catechism", slug: "catechism", order_index: 3},
  %{name: "Q&A", slug: "qna", order_index: 4},
  %{name: "Media", slug: "media", order_index: 5}
]

content_categories =
  Enum.map(content_categories_attrs, fn attrs ->
    Repo.insert!(
      struct(ContentCategory, Map.put(attrs, :is_active, true)),
      on_conflict: {:replace, [:name, :order_index, :is_active, :updated_at]},
      conflict_target: [:slug],
      returning: true
    )
  end)

# Standard three-stage approval ladder, matching the roles seeded above:
#   document -> congregation Rector (creates/edits content)
#   reviewer -> District Rector (doctrinal review)
#   approver ->  Apostle (final sign-off)
role_by_slug = Map.new(roles, fn {role, _granted} -> {role.slug, role} end)

{:ok, standard_review} =
  case Repo.get_by(WorkFlow, name: "Standard Review") do
    nil ->
      %WorkFlow{}
      |> WorkFlow.changeset(%{
        name: "Standard Review",
        status: "active",
        description: "Document -> District Rector review -> Apostle approval"
      })
      |> Repo.insert()

    %WorkFlow{} = wf ->
      {:ok, wf}
  end

standard_review_steps = [
  %{name: "Document", stage_type: :document, role_slug: "congregation-rector", order_index: 0},
  %{name: "Doctrinal Review", stage_type: :reviewer, role_slug: "district-rector", order_index: 100_000},
  %{name: "Final Approval", stage_type: :approver, role_slug: "apostle", order_index: 200_000}
]

for step_attrs <- standard_review_steps do
  role = Map.fetch!(role_by_slug, step_attrs.role_slug)

  existing =
    Repo.get_by(WorkFlowStep, work_flow_id: standard_review.id, stage_type: step_attrs.stage_type)

  if is_nil(existing) do
    %WorkFlowStep{}
    |> WorkFlowStep.changeset(%{
      name: step_attrs.name,
      stage_type: step_attrs.stage_type,
      work_flow_id: standard_review.id,
      role_id: role.id,
      order_index: step_attrs.order_index
    })
    |> Repo.insert!()
  end
end

# Every category defaults to Standard Review for now — split this out
# per-category later if Media ends up wanting a lighter workflow
# (e.g. Media Coordinator only, no Bishop/Apostle stages).
content_categories =
  for category <- content_categories do
    category
    |> ContentCategory.changeset(%{default_work_flow_id: standard_review.id})
    |> Repo.update!()
  end

IO.puts("Seeded #{length(content_categories)} content categories and the Standard Review workflow.")

# ── 6. Sample documents ──────────────────────────────────────────────
#
# Inserted straight into content_items so the seeds don't depend on the
# document schema module. All start at the Document stage, authored by
# dev@dev.com (District Rector). Re-running is safe: rows are keyed on slug.

author = Repo.get_by!(User, email: "dev@dev.com")

document_step =
  Repo.get_by!(WorkFlowStep, work_flow_id: standard_review.id, stage_type: :document)

categories_by_slug = Map.new(content_categories, &{&1.slug, &1})
now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

sample_documents = [
  %{
    title: "Courtship and Marriage",
    slug: "courtship-and-marriage",
    category: "doctrine-articles",
    summary: "Guidance on courtship and marriage",
    duration_label: "10 min read",
    body: "<p>Courtship and Marriage</p>"
  },
  %{
    title: "The Lord's Prayer",
    slug: "the-lords-prayer",
    category: "catechism",
    summary: "An explanation of the Lord's Prayer",
    duration_label: "5 min read",
    body: "<p>An explanation of the Lord's Prayer.</p>"
  },
  %{
    title: "Reading the Gospel of John",
    slug: "reading-the-gospel-of-john",
    category: "bible-content",
    summary: "A study guide",
    duration_label: "15 min read",
    body: "<p>A study guide to the Gospel of John.</p>"
  },
  %{
    title: "Why do we pray?",
    slug: "why-do-we-pray",
    category: "qna",
    summary: "Common questions about prayer",
    duration_label: "3 min read",
    body: "<p>Common questions about prayer.</p>"
  }
]

document_rows =
  for d <- sample_documents do
    %{
      title: d.title,
      slug: d.slug,
      summary: d.summary,
      body: d.body,
      duration_label: d.duration_label,
      status: "document",
      category_id: Map.fetch!(categories_by_slug, d.category).id,
      workflow_id: standard_review.id,
      current_step_id: document_step.id,
      author_id: author.id,
      inserted_at: now,
      updated_at: now
    }
  end

Repo.insert_all("content_items", document_rows,
  on_conflict: :nothing,
  conflict_target: [:slug]
)

IO.puts("Seeded #{length(document_rows)} sample documents.")
