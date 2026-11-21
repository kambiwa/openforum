defmodule Openforum.Context.WorkingAreas do
  @moduledoc """
  Manages the configurable working-area tree and dated user memberships.

  Hierarchy mutations are serialized with a transaction-scoped advisory lock so
  concurrent parent changes cannot introduce a cycle.
  """

  import Ecto.Query, warn: false

  alias Openforum.Accounts.User
  alias Openforum.Repo
  alias OpenforumWeb.Schema.UserWorkingAreaMembership
  alias OpenforumWeb.Schema.WorkingArea

  @hierarchy_lock 2_045_182_441

  def list_working_areas(table_params \\ %{}, filters \\ %{}) do
    page = OpenforumWeb.Pagination.param_value(table_params, "page", 1)
    page_size = OpenforumWeb.Pagination.param_value(table_params, "page_size", 10)
    order_by = table_params["order_by"] || %{"sort_field" => "id", "sort_direction" => "desc"}
    search = get_in(table_params, ["filter", "isearch"]) || ""
    status = filters[:status_filter] || filters["status_filter"] || ""

    WorkingArea
    |> apply_search(search)
    |> apply_status(status)
    |> apply_order(order_by)
    |> Repo.paginate(page: page, page_size: page_size)
  end

  def list_working_area_tree do
    WorkingArea
    |> order_by([area], asc: area.order_index, asc: area.name, asc: area.id)
    |> Repo.all()
  end

  def get_working_area!(id), do: Repo.get!(WorkingArea, id)

  def get_working_area(id), do: Repo.get(WorkingArea, id)

  def create_working_area(attrs \\ %{}) do
    %WorkingArea{}
    |> WorkingArea.changeset(attrs)
    |> Repo.insert()
  end

  def update_working_area(%WorkingArea{} = working_area, attrs) do
    Repo.transaction(fn ->
      lock_hierarchy!()
      changeset = WorkingArea.changeset(working_area, attrs)
      new_parent_id = Ecto.Changeset.get_field(changeset, :parent_id)

      if changeset.valid? and parent_is_descendant?(working_area.id, new_parent_id) do
        Repo.rollback(
          Ecto.Changeset.add_error(changeset, :parent_id, "would create a circular hierarchy")
        )
      end

      case Repo.update(changeset) do
        {:ok, updated_area} -> updated_area
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
    |> unwrap_transaction()
  end

  def activate_working_area(%WorkingArea{} = working_area),
    do: update_working_area(working_area, %{is_active: true})

  def deactivate_working_area(%WorkingArea{} = working_area),
    do: update_working_area(working_area, %{is_active: false})

  def delete_working_area(%WorkingArea{} = working_area) do
    if has_dependents?(working_area.id) do
      {:error, :has_dependents}
    else
      Repo.delete(working_area)
    end
  end

  def change_working_area(%WorkingArea{} = working_area, attrs \\ %{}) do
    WorkingArea.changeset(working_area, attrs)
  end

  def list_child_working_areas(parent_id) do
    WorkingArea
    |> where([area], area.parent_id == ^parent_id)
    |> order_by([area], asc: area.order_index, asc: area.name, asc: area.id)
    |> Repo.all()
  end

  def list_parent_options(exclude_id \\ nil) do
    excluded_ids =
      if exclude_id do
        [cast_id(exclude_id) | Enum.map(list_descendant_working_areas(exclude_id), & &1.id)]
      else
        []
      end

    WorkingArea
    |> where([area], area.id not in ^excluded_ids)
    |> order_by([area], asc: area.order_index, asc: area.name, asc: area.id)
    |> Repo.all()
  end

  def list_descendant_working_areas(id) do
    ids =
      recursive_area_ids!(
        """
        WITH RECURSIVE area_tree(id) AS (
          SELECT id FROM working_area WHERE parent_id = $1
          UNION ALL
          SELECT child.id
          FROM working_area AS child
          JOIN area_tree AS parent ON child.parent_id = parent.id
        )
        SELECT id FROM area_tree
        """,
        id
      )

    list_areas_by_ids(ids)
  end

  def list_ancestor_working_areas(id) do
    ids =
      recursive_area_ids!(
        """
        WITH RECURSIVE area_tree(id, parent_id, depth) AS (
          SELECT id, parent_id, 0 FROM working_area WHERE id = $1
          UNION ALL
          SELECT parent.id, parent.parent_id, area_tree.depth + 1
          FROM working_area AS parent
          JOIN area_tree ON area_tree.parent_id = parent.id
        )
        SELECT id FROM area_tree WHERE id <> $1 ORDER BY depth DESC
        """,
        id
      )

    list_areas_by_ids(ids)
  end

  def assign_user_to_working_area(user_id, working_area_id, attrs \\ %{}) do
    with %WorkingArea{is_active: true} <- Repo.get(WorkingArea, working_area_id),
         %User{} <- Repo.get(User, user_id) do
      attrs =
        attrs
        |> put_param(:user_id, user_id)
        |> put_param(:working_area_id, working_area_id)
        |> put_default(:status, "active")
        |> put_default(:starts_on, Date.utc_today())

      case Repo.get_by(UserWorkingAreaMembership,
             user_id: cast_id(user_id),
             working_area_id: cast_id(working_area_id),
             status: "active"
           ) do
        nil ->
          %UserWorkingAreaMembership{}
          |> UserWorkingAreaMembership.changeset(attrs)
          |> Repo.insert()

        %UserWorkingAreaMembership{} ->
          {:error, :already_assigned}
      end
    else
      %WorkingArea{is_active: false} -> {:error, :working_area_inactive}
      nil -> {:error, :not_found}
    end
  end

  def remove_user_from_working_area(user_id, working_area_id) do
    case Repo.get_by(UserWorkingAreaMembership,
           user_id: cast_id(user_id),
           working_area_id: cast_id(working_area_id),
           status: "active"
         ) do
      nil ->
        {:error, :not_found}

      membership ->
        end_date =
          if Date.compare(membership.starts_on, Date.utc_today()) == :gt,
            do: membership.starts_on,
            else: Date.utc_today()

        membership
        |> UserWorkingAreaMembership.changeset(%{status: "inactive", ends_on: end_date})
        |> Repo.update()
    end
  end

  def list_working_area_members(working_area_id, opts \\ []) do
    active_only? = Keyword.get(opts, :active_only, true)

    UserWorkingAreaMembership
    |> where([membership], membership.working_area_id == ^working_area_id)
    |> maybe_active(active_only?)
    |> order_by([membership], asc: membership.starts_on, asc: membership.id)
    |> preload(:user)
    |> Repo.all()
  end

  def change_membership(membership \\ %UserWorkingAreaMembership{}, attrs \\ %{}) do
    UserWorkingAreaMembership.changeset(membership, attrs)
  end

  def list_working_areas_for_user(user_id, opts \\ []) do
    active_only? = Keyword.get(opts, :active_only, true)

    from(membership in UserWorkingAreaMembership,
      join: area in assoc(membership, :working_area),
      where: membership.user_id == ^cast_id(user_id),
      preload: [working_area: area],
      order_by: [asc: area.order_index, asc: area.name, asc: area.id]
    )
    |> maybe_active(active_only?)
    |> Repo.all()
  end

  def list_users_available_for_working_area(working_area_id) do
    existing_user_ids =
      UserWorkingAreaMembership
      |> where(
        [membership],
        membership.working_area_id == ^working_area_id and membership.status == "active"
      )
      |> select([membership], membership.user_id)
      |> Repo.all()

    User
    |> where([user], user.id not in ^existing_user_ids)
    |> order_by([user], asc: user.last_name, asc: user.first_name, asc: user.id)
    |> Repo.all()
  end

  # Compatibility wrappers for legacy area screens. They now return the
  # generic working-area collection and do not encode NAC levels.
  def list_congregation(params \\ %{}, filters \\ %{}), do: list_working_areas(params, filters)

  def list_district_rector_areas(params \\ %{}, filters \\ %{}),
    do: list_working_areas(params, filters)

  def list_lead_apostle_areas(params \\ %{}, filters \\ %{}),
    do: list_working_areas(params, filters)

  def list_district_apostle_areas(params \\ %{}, filters \\ %{}),
    do: list_working_areas(params, filters)

  defp parent_is_descendant?(_id, nil), do: false
  defp parent_is_descendant?(id, id), do: true

  defp parent_is_descendant?(id, parent_id) do
    Enum.member?(
      recursive_area_ids!(
        """
        WITH RECURSIVE area_tree(id) AS (
          SELECT id FROM working_area WHERE parent_id = $1
          UNION ALL
          SELECT child.id
          FROM working_area AS child
          JOIN area_tree AS parent ON child.parent_id = parent.id
        )
        SELECT id FROM area_tree
        """,
        id
      ),
      cast_id(parent_id)
    )
  end

  defp recursive_area_ids!(sql, id) do
    %{rows: rows} = Repo.query!(sql, [cast_id(id)])
    Enum.map(rows, fn [area_id] -> area_id end)
  end

  defp list_areas_by_ids([]), do: []

  defp list_areas_by_ids(ids) do
    areas_by_id =
      WorkingArea
      |> where([area], area.id in ^ids)
      |> Repo.all()
      |> Map.new(&{&1.id, &1})

    Enum.map(ids, &Map.get(areas_by_id, &1))
    |> Enum.reject(&is_nil/1)
  end

  defp lock_hierarchy! do
    Repo.query!("SELECT pg_advisory_xact_lock($1)", [@hierarchy_lock])
  end

  defp has_dependents?(id) do
    Repo.exists?(from(area in WorkingArea, where: area.parent_id == ^id)) or
      Repo.exists?(
        from(membership in UserWorkingAreaMembership, where: membership.working_area_id == ^id)
      ) or
      Repo.exists?(from(user in User, where: user.working_area_id == ^id)) or
      Repo.exists?(from(lead in OpenforumWeb.Schema.AreaLead, where: lead.working_area_id == ^id))
  end

  defp maybe_active(query, true) do
    today = Date.utc_today()

    where(
      query,
      [membership],
      membership.status == "active" and membership.starts_on <= ^today and
        (is_nil(membership.ends_on) or membership.ends_on >= ^today)
    )
  end

  defp maybe_active(query, false), do: query

  defp unwrap_transaction({:ok, result}), do: {:ok, result}
  defp unwrap_transaction({:error, reason}), do: {:error, reason}

  defp apply_search(query, search) when search in [nil, ""], do: query

  defp apply_search(query, search) do
    term = "%#{search}%"
    where(query, [area], ilike(area.name, ^term) or ilike(area.description, ^term))
  end

  defp apply_status(query, status) when status in [nil, ""], do: query
  defp apply_status(query, "active"), do: where(query, [area], area.is_active == true)
  defp apply_status(query, "inactive"), do: where(query, [area], area.is_active == false)
  defp apply_status(query, _status), do: query

  defp apply_order(query, %{"sort_field" => field, "sort_direction" => direction}) do
    order = if direction == "asc", do: :asc, else: :desc

    case field do
      "name" -> order_by(query, [area], [{^order, area.name}])
      "order_index" -> order_by(query, [area], [{^order, area.order_index}, asc: area.name])
      "inserted_at" -> order_by(query, [area], [{^order, area.inserted_at}])
      _ -> order_by(query, [area], [{^order, area.id}])
    end
  end

  defp apply_order(query, _), do: order_by(query, [area], asc: area.order_index, asc: area.name)

  defp put_param(attrs, key, value) do
    if Map.has_key?(attrs, Atom.to_string(key)),
      do: Map.put(attrs, Atom.to_string(key), value),
      else: Map.put(attrs, key, value)
  end

  defp put_default(attrs, key, value) do
    if Map.has_key?(attrs, key) or Map.has_key?(attrs, Atom.to_string(key)),
      do: attrs,
      else: Map.put(attrs, key, value)
  end

  defp cast_id(id) when is_binary(id), do: String.to_integer(id)
  defp cast_id(id), do: id
end
