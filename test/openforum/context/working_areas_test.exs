defmodule Openforum.Context.WorkingAreasTest do
  use Openforum.DataCase

  alias Openforum.Accounts
  alias Openforum.Context.WorkingAreas
  alias Openforum.Repo
  alias OpenforumWeb.Schema.UserWorkingAreaMembership

  defp user_fixture(attrs \\ %{}) do
    attrs =
      Map.merge(
        %{
          first_name: "Ada",
          last_name: "Lovelace",
          email: "user-#{System.unique_integer([:positive])}@example.com",
          password: "correct horse battery"
        },
        attrs
      )

    {:ok, user} = Accounts.register_user(attrs)
    user
  end

  defp area_fixture(attrs) do
    {:ok, area} =
      WorkingAreas.create_working_area(
        Map.merge(%{name: "Area #{System.unique_integer([:positive])}"}, attrs)
      )

    area
  end

  test "creates and updates configurable working areas" do
    assert {:ok, area} = WorkingAreas.create_working_area(%{name: "Root", order_index: 3})
    assert area.is_active
    assert area.parent_id == nil
    assert area.order_index == 3

    assert {:ok, updated} = WorkingAreas.update_working_area(area, %{description: "Updated"})
    assert updated.description == "Updated"

    assert {:ok, deactivated} = WorkingAreas.deactivate_working_area(updated)
    refute deactivated.is_active
    assert {:ok, activated} = WorkingAreas.activate_working_area(deactivated)
    assert activated.is_active
  end

  test "returns children, descendants and ancestors through arbitrary depth" do
    root = area_fixture(%{name: "Root"})
    {:ok, child} = WorkingAreas.create_working_area(%{name: "Child", parent_id: root.id})
    {:ok, leaf} = WorkingAreas.create_working_area(%{name: "Leaf", parent_id: child.id})

    assert Enum.map(WorkingAreas.list_child_working_areas(root.id), & &1.id) == [child.id]

    assert Enum.map(WorkingAreas.list_descendant_working_areas(root.id), & &1.id) |> MapSet.new() ==
             MapSet.new([child.id, leaf.id])

    assert Enum.map(WorkingAreas.list_ancestor_working_areas(leaf.id), & &1.id) == [
             root.id,
             child.id
           ]
  end

  test "rejects self-parenting, circular hierarchies and invalid parents" do
    root = area_fixture(%{name: "Root"})
    {:ok, child} = WorkingAreas.create_working_area(%{name: "Child", parent_id: root.id})

    assert {:error, changeset} = WorkingAreas.update_working_area(root, %{parent_id: root.id})
    assert "cannot be its own parent" in errors_on(changeset).parent_id

    assert {:error, changeset} = WorkingAreas.update_working_area(root, %{parent_id: child.id})
    assert "would create a circular hierarchy" in errors_on(changeset).parent_id

    assert {:error, changeset} =
             WorkingAreas.create_working_area(%{name: "Invalid Parent", parent_id: -1})

    assert errors_on(changeset).parent_id
  end

  test "prevents deletion when an area has dependent children, memberships or legacy user links" do
    root = area_fixture(%{name: "Root"})
    _child = area_fixture(%{name: "Child", parent_id: root.id})
    assert {:error, :has_dependents} = WorkingAreas.delete_working_area(root)

    leaf = area_fixture(%{name: "Leaf"})
    user = user_fixture(%{working_area_id: leaf.id})
    assert {:error, :has_dependents} = WorkingAreas.delete_working_area(leaf)

    Repo.update!(Ecto.Changeset.change(user, working_area_id: nil))
    assert {:ok, _deleted} = WorkingAreas.delete_working_area(leaf)
  end

  test "supports multiple memberships and retains deactivated membership history" do
    user = user_fixture()
    first = area_fixture(%{name: "First"})
    second = area_fixture(%{name: "Second"})
    today = Date.utc_today()

    assert {:ok, first_membership} =
             WorkingAreas.assign_user_to_working_area(user.id, first.id, %{starts_on: today})

    assert {:ok, second_membership} =
             WorkingAreas.assign_user_to_working_area(user.id, second.id, %{
               starts_on: Date.add(today, -1),
               ends_on: Date.add(today, 4)
             })

    assert length(WorkingAreas.list_working_areas_for_user(user.id)) == 2

    assert Enum.map(WorkingAreas.list_working_area_members(first.id), & &1.id) == [
             first_membership.id
           ]

    assert {:error, :already_assigned} =
             WorkingAreas.assign_user_to_working_area(user.id, first.id, %{starts_on: today})

    assert {:ok, inactive} = WorkingAreas.remove_user_from_working_area(user.id, first.id)
    assert inactive.status == "inactive"
    assert inactive.ends_on == today
    assert WorkingAreas.list_working_area_members(first.id) == []
    assert Repo.get!(UserWorkingAreaMembership, first_membership.id).status == "inactive"
    assert Repo.get!(UserWorkingAreaMembership, second_membership.id).status == "active"
  end

  test "rejects invalid membership periods and inactive areas" do
    user = user_fixture()
    area = area_fixture(%{name: "Closed", is_active: false})
    today = Date.utc_today()

    assert {:error, :working_area_inactive} =
             WorkingAreas.assign_user_to_working_area(user.id, area.id, %{starts_on: today})

    active_area = area_fixture(%{name: "Open"})

    assert {:error, changeset} =
             WorkingAreas.assign_user_to_working_area(user.id, active_area.id, %{
               starts_on: today,
               ends_on: Date.add(today, -1)
             })

    assert errors_on(changeset).ends_on
  end

  test "does not activate future or expired memberships in user area results" do
    user = user_fixture()
    future_area = area_fixture(%{name: "Future"})
    expired_area = area_fixture(%{name: "Expired"})
    today = Date.utc_today()

    assert {:ok, _} =
             WorkingAreas.assign_user_to_working_area(user.id, future_area.id, %{
               starts_on: Date.add(today, 1)
             })

    assert {:ok, _} =
             WorkingAreas.assign_user_to_working_area(user.id, expired_area.id, %{
               starts_on: Date.add(today, -4),
               ends_on: Date.add(today, -1)
             })

    assert WorkingAreas.list_working_areas_for_user(user.id) == []
    assert length(WorkingAreas.list_working_areas_for_user(user.id, active_only: false)) == 2
  end

  test "preserves legacy user area relationships alongside memberships" do
    area = area_fixture(%{name: "Legacy"})
    user = user_fixture(%{working_area_id: area.id})

    assert Repo.get!(Openforum.Accounts.User, user.id).working_area_id == area.id

    assert {:ok, membership} =
             WorkingAreas.assign_user_to_working_area(user.id, area.id, %{
               starts_on: Date.utc_today()
             })

    assert membership.status == "active"
    assert Repo.get!(Openforum.Accounts.User, user.id).working_area_id == area.id
  end
end
