defmodule Openforum.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Openforum.Repo

  alias Openforum.Accounts.{User, UserToken, UserNotifier}

  def list_users(table_params \\ %{}, filters \\ %{}) do
    page = OpenforumWeb.Pagination.param_value(table_params, "page", 1)
    page_size = OpenforumWeb.Pagination.param_value(table_params, "page_size", 10)
    order_by = table_params["order_by"] || %{"sort_field" => "id", "sort_direction" => "desc"}
    search = get_in(table_params, ["filter", "isearch"]) || ""
    status = filters[:status_filter] || filters["status_filter"] || ""

    User
    |> preload(:roles)
    |> apply_search(search)
    |> apply_status(status)
    |> apply_order(order_by)
    |> Repo.paginate(page: page, page_size: page_size)
  end

  ## ======================
  ## DATABASE GETTERS
  ## ======================

  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password) and user.is_active, do: user
  end

  def get_user!(id), do: Repo.get!(User, id)

  ## ======================
  ## REGISTRATION
  ## ======================

  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  def change_user_registration(user, attrs \\ %{}) do
    User.registration_changeset(user, attrs)
  end

  def update_user(%User{} = user, attrs) do
    user
    |> User.update_changeset(attrs)
    |> Repo.update()
  end

  def change_user(%User{} = user, attrs \\ %{}) do
    User.update_changeset(user, attrs)
  end

  def update_user_profile(%User{} = user, attrs) do
    user
    |> User.profile_changeset(attrs)
    |> Repo.update()
  end

  def change_user_profile(%User{} = user, attrs \\ %{}) do
    User.profile_changeset(user, attrs)
  end

  def set_user_active(%User{} = user, active?) when is_boolean(active?) do
    case user |> Ecto.Changeset.change(is_active: active?) |> Repo.update() do
      {:ok, updated_user} ->
        tokens =
          if active? do
            []
          else
            token_query =
              from(token in UserToken,
                where: token.user_id == ^user.id and token.context == "session",
                select: %{token: token.token}
              )

            Repo.all(token_query)
          end

        unless active? do
          Repo.delete_all(
            from(token in UserToken,
              where: token.user_id == ^user.id and token.context == "session"
            )
          )
        end

        {:ok, updated_user, tokens}

      error ->
        error
    end
  end

  def delete_user(%User{} = user), do: Repo.delete(user)

  ## ======================
  ## EMAIL (OPTIONAL KEEP)
  ## ======================

  def change_user_email(user, attrs \\ %{}, opts \\ []) do
    User.email_changeset(user, attrs, opts)
  end

  def update_user_email(user, token) do
    context = "change:#{user.email}"

    Repo.transact(fn ->
      with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
           %UserToken{sent_to: email} <- Repo.one(query),
           {:ok, user} <- Repo.update(User.email_changeset(user, %{email: email})),
           {_count, _} <-
             Repo.delete_all(from(UserToken, where: [user_id: ^user.id, context: ^context])) do
        {:ok, user}
      else
        _ -> {:error, :transaction_aborted}
      end
    end)
  end

  ## ======================
  ## PASSWORD
  ## ======================

  def change_user_password(user, attrs \\ %{}, opts \\ []) do
    User.password_changeset(user, attrs, opts)
  end

  def update_user_password(user, attrs) do
    user
    |> User.password_changeset(attrs)
    |> update_user_and_delete_all_tokens()
  end

  def deliver_user_reset_password_instructions(%User{} = user, url_fun)
      when is_function(url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "reset_password")
    Repo.insert!(user_token)

    UserNotifier.deliver_reset_password_instructions(user, url_fun.(encoded_token))
  end

  def valid_password_reset_token?(token) when is_binary(token) do
    case UserToken.verify_password_reset_token_query(token) do
      {:ok, query} -> Repo.exists?(query)
      :error -> false
    end
  end

  def valid_password_reset_token?(_token), do: false

  def reset_user_password(token, attrs) when is_binary(token) do
    with {:ok, query} <- UserToken.verify_password_reset_token_query(token),
         %User{} = user <- Repo.one(query) do
      user
      |> User.password_changeset(attrs)
      |> update_user_and_delete_all_tokens()
    else
      _ -> {:error, :invalid_token}
    end
  end

  ## ======================
  ## SESSION
  ## ======================

  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)

    case Repo.one(query) do
      {user, token_inserted_at} -> {Repo.preload(user, :roles), token_inserted_at}
      nil -> nil
    end
  end

  def delete_user_session_token(token) do
    Repo.delete_all(from(UserToken, where: [token: ^token, context: "session"]))
    :ok
  end

  ## ======================
  ## EMAIL NOTIFICATIONS (OPTIONAL)
  ## ======================

  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)

    UserNotifier.deliver_update_email_instructions(
      user,
      update_email_url_fun.(encoded_token)
    )
  end

  ## ======================
  ## INTERNAL HELPERS
  ## ======================

  defp update_user_and_delete_all_tokens(changeset) do
    Repo.transact(fn ->
      with {:ok, user} <- Repo.update(changeset) do
        tokens = Repo.all_by(UserToken, user_id: user.id)

        Repo.delete_all(from(t in UserToken, where: t.id in ^Enum.map(tokens, & &1.id)))

        {:ok, {user, tokens}}
      end
    end)
  end

  # ── Private query helpers ────────────────────────────────────────────

  defp apply_search(query, ""), do: query
  defp apply_search(query, nil), do: query

  defp apply_search(query, search) do
    term = "%#{search}%"

    where(
      query,
      [f],
      ilike(f.first_name, ^term) or ilike(f.last_name, ^term) or ilike(f.email, ^term)
    )
  end

  defp apply_status(query, ""), do: query
  defp apply_status(query, nil), do: query

  defp apply_status(query, "active"), do: where(query, [user], user.is_active == true)
  defp apply_status(query, "inactive"), do: where(query, [user], user.is_active == false)
  defp apply_status(query, _status), do: query

  defp apply_order(query, %{"sort_field" => field, "sort_direction" => direction}) do
    order = if direction == "asc", do: :asc, else: :desc

    case field do
      "first_name" -> order_by(query, [f], [{^order, f.first_name}])
      "last_name" -> order_by(query, [f], [{^order, f.last_name}])
      "email" -> order_by(query, [f], [{^order, f.email}])
      "status" -> order_by(query, [f], [{^order, f.status}])
      "inserted_at" -> order_by(query, [f], [{^order, f.inserted_at}])
      _ -> order_by(query, [f], [{^order, f.id}])
    end
  end

  defp apply_order(query, _), do: order_by(query, [f], desc: f.id)
end
