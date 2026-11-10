defmodule OpenforumWeb.UserSessionController do
  use OpenforumWeb, :controller

  alias Openforum.Accounts
  alias OpenforumWeb.UserAuth

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  # Email and password login
  defp create(conn, %{"user" => user_params}, info) do
    %{"email" => email, "password" => password} = user_params

    case Accounts.get_user_by_email_and_password(email, password) do
      nil ->
        # Prevent user enumeration by using a generic error message.
        conn
        |> put_flash(:error, "Invalid email or password")
        |> put_flash(:email, String.slice(email, 0, 160))
        |> redirect(to: ~p"/users/log-in")

      user ->
        conn
        |> put_flash(:info, info)
        |> UserAuth.log_in_user(user, user_params)
    end
  end

  def update_password(conn, %{"user" => user_params} = params) do
    user = conn.assigns.current_scope.user
    true = Accounts.sudo_mode?(user)

    {:ok, {_user, expired_tokens}} =
      Accounts.update_user_password(user, user_params)

    # Disconnect existing sessions using expired tokens.
    UserAuth.disconnect_sessions(expired_tokens)

    conn
    |> put_session(:user_return_to, ~p"/users/settings")
    |> create(params, "Password updated successfully!")
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end
end
