defmodule OpenforumWeb.WorkingAreasLiveTest do
  use OpenforumWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Openforum.Accounts
  alias Openforum.Context.WorkingAreas

  setup %{conn: conn} do
    {:ok, user} =
      Accounts.register_user(%{
        first_name: "Test",
        last_name: "Administrator",
        email: "working-area-#{System.unique_integer([:positive])}@example.com",
        password: "correct horse battery"
      })

    {:ok, conn: OpenforumWeb.ConnCase.log_in_user(conn, user)}
  end

  test "renders the generic hierarchy and membership manager", %{conn: conn} do
    {:ok, root} = WorkingAreas.create_working_area(%{name: "Configured Root", order_index: 1})

    {:ok, _child} =
      WorkingAreas.create_working_area(%{name: "Configured Child", parent_id: root.id})

    {:ok, view, _html} = live(conn, "/admin/working_areas")

    assert has_element?(view, "#working-area-tree")
    assert has_element?(view, "#working-area-#{root.id}")
    assert has_element?(view, "#new-working-area")
    assert has_element?(view, "#working-area-filter")

    view
    |> element("#working-area-#{root.id} button[phx-click='select_area']")
    |> render_click()

    assert has_element?(view, "#membership-form")
    assert has_element?(view, "#membership-form select")
  end

  test "authentication is required for the working area administration route", %{} do
    conn =
      Phoenix.ConnTest.build_conn()
      |> Plug.Test.init_test_session(%{})
      |> get("/admin/working_areas")

    assert redirected_to(conn) == "/users/log-in"
  end
end
