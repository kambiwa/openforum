defmodule OpenforumWeb.Auth.RolesPermissions.Index do
  use OpenforumWeb, :live_view


  @impl true
  def mount(_params, _session, socket) do
    roles = mock_roles()
    selected = List.first(roles)

    {:ok,
    socket
    |> assign(:current_scope, "")
    |> assign(:mobile_menu_open, false)
    |> assign(:page_title, "Roles & Permissions")
    |> assign(:current_page, :roles_permissions)
    |> assign(:roles, roles)
    |> assign(:active_tab, :permissions)
    |> assign_selected(selected)}
  end

  @impl true
  def handle_event("select_role", %{"id" => id}, socket) do
    role = Enum.find(socket.assigns.roles, &(&1.id == id))
    {:noreply, socket |> assign(:active_tab, :permissions) |> assign_selected(role)}
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_tab, String.to_existing_atom(tab))}
  end

  def handle_event("toggle_permission", %{"category" => category, "action" => action}, socket) do
    # TODO: replace with Openforum.Context.Roles.toggle_role_permission/2
    role = socket.assigns.selected_role

    updated_permissions =
      Map.update!(role.permissions, category, fn actions ->
        MapSet.new(actions, fn {a, enabled} -> if a == action, do: {a, !enabled}, else: {a, enabled} end)
        |> Enum.to_list()
      end)

    updated_role = %{role | permissions: updated_permissions}

    roles =
      Enum.map(socket.assigns.roles, fn
        r when r.id == updated_role.id -> updated_role
        r -> r
      end)

    {:noreply,
     socket
     |> assign(:roles, roles)
     |> assign(:selected_role, updated_role)}
  end

  defp assign_selected(socket, role), do: assign(socket, :selected_role, role)

  # ── Mock data (shape mirrors Context.Roles output) ──────────────────

    defp mock_roles do
    [
      %{
        id: "1",
        initial: "A",
        name: "District Apostle",
        description: "Final sign-off, approves stage 3 (Lead Apostle Area)",
        user_count: 2,
        assigned_users: [
          %{name: "Apostle Chanda Mulenga", email: "c.mulenga@nac.org"},
          %{name: "Apostle Ruth Zulu", email: "r.zulu@nac.org"}
        ],
        permissions: %{
          "Bible Content" => [{"View", true}, {"Create", false}, {"Edit", false}, {"Publish", true}, {"Delete", false}],
          "Doctrine Articles" => [{"View", true}, {"Create", false}, {"Edit", false}, {"Publish", true}, {"Delete", false}],
          "Catechism" => [{"View", true}, {"Create", false}, {"Edit", false}, {"Publish", true}, {"Delete", false}],
          "Approval Queue" => [{"View", true}, {"Create", false}, {"Edit", false}, {"Approve", true}, {"Reject", true}]
        }
      },
      %{
        id: "2",
        initial: "R",
        name: "District Rector",
        description: "Reviews submitted content and approves stage 1 (Congregation)",
        user_count: 3,
        assigned_users: [],
        permissions: %{
          "Bible Content" => [{"View", true}, {"Create", true}, {"Edit", true}, {"Publish", false}, {"Delete", false}],
          "Doctrine Articles" => [{"View", true}, {"Create", true}, {"Edit", true}, {"Publish", false}, {"Delete", false}],
          "Catechism" => [{"View", true}, {"Create", true}, {"Edit", true}, {"Publish", false}, {"Delete", false}],
          "Approval Queue" => [{"View", true}, {"Create", false}, {"Edit", false}, {"Approve", false}, {"Reject", false}]
        }
      },
      %{
        id: "3",
        initial: "B",
        name: "Bishop",
        description: "Performs doctrinal review, approves stage 2 (Apostle Area)",
        user_count: 1,
        assigned_users: [],
        permissions: %{
          "Bible Content" => [{"View", true}, {"Create", false}, {"Edit", false}, {"Publish", false}, {"Delete", false}],
          "Doctrine Articles" => [{"View", true}, {"Create", false}, {"Edit", true}, {"Publish", false}, {"Delete", false}],
          "Catechism" => [{"View", true}, {"Create", false}, {"Edit", false}, {"Publish", false}, {"Delete", false}],
          "Approval Queue" => [{"View", true}, {"Create", false}, {"Edit", false}, {"Approve", true}, {"Reject", true}]
        }
      },
      %{
        id: "4",
        initial: "M",
        name: "Media Coordinator",
        description: "Uploads and manages media assets across categories",
        user_count: 2,
        assigned_users: [],
        permissions: %{
          "Media" => [{"View", true}, {"Create", true}, {"Edit", true}, {"Publish", true}, {"Delete", false}],
          "Q&A" => [{"View", true}, {"Create", true}, {"Edit", false}, {"Publish", false}, {"Delete", false}],
          "Approval Queue" => [{"View", true}, {"Create", false}, {"Edit", false}, {"Approve", false}, {"Reject", false}]
        }
      }
    ]
  end
end
