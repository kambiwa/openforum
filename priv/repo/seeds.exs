# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Openforum.Repo.insert!(%Openforum.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Openforum.Repo
alias Openforum.Accounts
alias Openforum.Accounts.User
alias OpenforumWeb.Schema.{Permission, Role, RolePermission, RoleAssignment}

import Ecto.Query

# ------------- user-------------
alias Openforum.Accounts
alias Openforum.Accounts.User

# ── 0. Users ─────────────────────────────────────────────────────────
#
# Registers the users referenced in the role-assignment section below,
# and confirms them immediately so they can log in right away in dev.

users_attrs = [
  %{first_name: "Chanda", last_name: "Mulenga", email: "dev@dev.com", password: "dev@dev.com"},
  %{first_name: "Ruth", last_name: "Zulu", email: "admin@dev.com", password: "admin@dev.com"}
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
    description: "Final sign-off, approves stage 3 (Lead Apostle Area)",
    granted: [
      {"Bible Content", "View"}, {"Bible Content", "Publish"},
      {"Doctrine Articles", "View"}, {"Doctrine Articles", "Publish"},
      {"Catechism", "View"}, {"Catechism", "Publish"},
      {"Approval Queue", "View"}, {"Approval Queue", "Approve"}, {"Approval Queue", "Reject"}
    ]
  },
  %{
    name: "District Rector",
    slug: "district-rector",
    description: "Reviews submitted content and approves stage 1 (Congregation)",
    granted: [
      {"Bible Content", "View"}, {"Bible Content", "Create"}, {"Bible Content", "Edit"},
      {"Doctrine Articles", "View"}, {"Doctrine Articles", "Create"}, {"Doctrine Articles", "Edit"},
      {"Catechism", "View"}, {"Catechism", "Create"}, {"Catechism", "Edit"},
      {"Approval Queue", "View"}
    ]
  },
  %{
    name: "Bishop",
    slug: "bishop",
    description: "Performs doctrinal review, approves stage 2 (Apostle Area)",
    granted: [
      {"Bible Content", "View"},
      {"Doctrine Articles", "View"}, {"Doctrine Articles", "Edit"},
      {"Catechism", "View"},
      {"Approval Queue", "View"}, {"Approval Queue", "Approve"}, {"Approval Queue", "Reject"}
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

# ── 4. Optional: assign existing users to roles by email ───────────
#
# Adjust these emails to real accounts in your dev DB (e.g. ones created
# via phx.gen.auth registration) if you want the "Assigned Users" tab
# populated. Safe to leave as-is if those users don't exist yet — lookups
# just return nil and are skipped.

user_role_assignments = [
  {"c.mulenga@nac.org", "district-apostle"},
  {"r.zulu@nac.org", "district-apostle"}
]

for {email, role_slug} <- user_role_assignments do
  with %User{} = user <- Repo.get_by(User, email: email),
       %Role{} = role <- Repo.get_by(Role, slug: role_slug) do
    Repo.insert!(
      %RoleAssignment{role_id: role.id, user_id: user.id},
      on_conflict: :nothing,
      conflict_target: [:role_id, :user_id]
    )
  end
end

IO.puts("Seeded #{length(permissions)} permissions and #{length(roles)} roles.")
