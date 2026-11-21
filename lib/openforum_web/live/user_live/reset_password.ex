defmodule OpenforumWeb.UserLive.ResetPassword do
  use OpenforumWeb, :live_view

  alias Openforum.Accounts
  alias Openforum.Accounts.User

  @impl true
  def mount(params, _session, socket) do
    token = Map.get(params, "token")
    token_valid? = is_nil(token) or Accounts.valid_password_reset_token?(token)

    {:ok,
     socket
     |> assign(:page_title, "Reset Password")
     |> assign(:token, token)
     |> assign(:token_valid?, token_valid?)
     |> assign(:request_form, to_form(%{}, as: :user))
     |> assign(
       :password_form,
       to_form(Accounts.change_user_password(%User{}, %{}, hash_password: false))
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <main class="flex min-h-[calc(100vh-4rem)] items-center justify-center bg-[#FAFAF7] px-5 py-14">
        <section class="w-full max-w-md rounded-2xl border border-[#E5E7EB] bg-white p-7 shadow-sm sm:p-9">
          <div class="mb-7 text-center">
            <p class="text-xs font-semibold uppercase tracking-[0.14em] text-[#1769AA]">OpenForum</p>
            <h1 class="mt-3 text-2xl font-bold tracking-tight text-[#0B2E4F]">
              {if(is_nil(@token), do: "Reset your password", else: "Choose a new password")}
            </h1>
            <p class="mt-2 text-sm leading-relaxed text-[#6B7280]">
              <%= if is_nil(@token) do %>
                Enter the email address linked to your account and we’ll send you a reset link.
              <% else %>
                Your new password must be at least 6 characters long.
              <% end %>
            </p>
          </div>

          <%= cond do %>
            <% !is_nil(@token) and not @token_valid? -> %>
              <div class="rounded-xl border border-rose-200 bg-rose-50 p-4 text-center">
                <p class="text-sm font-semibold text-rose-800">
                  This reset link is invalid or has expired.
                </p>
                <.link
                  navigate={~p"/users/reset-password"}
                  class="mt-3 inline-flex text-sm font-semibold text-[#1769AA] hover:text-[#0B2E4F]"
                >
                  Request another link
                </.link>
              </div>
            <% is_nil(@token) -> %>
              <.form
                for={@request_form}
                id="request-password-reset-form"
                phx-submit="request_reset"
                class="space-y-5"
              >
                <.input
                  field={@request_form[:email]}
                  type="email"
                  label="Email address"
                  autocomplete="email"
                  required
                />
                <button
                  type="submit"
                  class="inline-flex w-full items-center justify-center rounded-lg bg-[#1769AA] px-5 py-3 text-sm font-semibold text-white transition hover:bg-[#0B2E4F]"
                >
                  Send reset link
                </button>
              </.form>
            <% true -> %>
              <.form
                for={@password_form}
                id="reset-password-form"
                phx-change="validate_password"
                phx-submit="reset_password"
                class="space-y-5"
              >
                <.input
                  field={@password_form[:password]}
                  type="password"
                  label="New password"
                  autocomplete="new-password"
                  required
                />
                <.input
                  field={@password_form[:password_confirmation]}
                  type="password"
                  label="Confirm new password"
                  autocomplete="new-password"
                  required
                />
                <button
                  type="submit"
                  class="inline-flex w-full items-center justify-center rounded-lg bg-[#1769AA] px-5 py-3 text-sm font-semibold text-white transition hover:bg-[#0B2E4F]"
                >
                  Save new password
                </button>
              </.form>
          <% end %>

          <p class="mt-6 text-center text-sm text-[#6B7280]">
            Remembered it?
            <.link
              navigate={~p"/users/log-in"}
              class="font-semibold text-[#1769AA] hover:text-[#0B2E4F]"
            >
              Back to sign in
            </.link>
          </p>
        </section>
      </main>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("request_reset", %{"user" => %{"email" => email}}, socket) do
    case Accounts.get_user_by_email(email) do
      %User{is_active: true} = user ->
        Accounts.deliver_user_reset_password_instructions(
          user,
          &url(~p"/users/reset-password/#{&1}")
        )

      _user ->
        :ok
    end

    {:noreply,
     put_flash(
       socket,
       :info,
       "If an active account matches that email, we’ll send a password reset link shortly."
     )}
  end

  def handle_event("validate_password", %{"user" => params}, socket) do
    changeset =
      %User{}
      |> Accounts.change_user_password(params, hash_password: false)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :password_form, to_form(changeset))}
  end

  def handle_event("reset_password", %{"user" => params}, socket) do
    case Accounts.reset_user_password(socket.assigns.token, params) do
      {:ok, {_user, _expired_tokens}} ->
        {:noreply,
         socket
         |> put_flash(:info, "Your password has been reset. Sign in with your new password.")
         |> push_navigate(to: ~p"/users/log-in")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :password_form, to_form(changeset, action: :insert))}

      {:error, :invalid_token} ->
        {:noreply,
         socket
         |> assign(:token_valid?, false)
         |> put_flash(:error, "This reset link is invalid or has expired. Request a new one.")}
    end
  end
end
