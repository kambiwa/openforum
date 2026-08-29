defmodule OpenforumWeb.UserLive.Registration do
  use OpenforumWeb, :live_view

  alias Openforum.Accounts
  alias Openforum.Accounts.User

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="flex min-h-[calc(100vh-4rem)] items-center justify-center bg-[#FAFAF7] px-6 py-16">
        <div class="w-full max-w-sm">
          <div class="text-center">
            <p class="text-xs font-semibold uppercase tracking-[0.14em] text-[#1769AA]">
              OpenForum
            </p>
            <h1 class="mt-3 text-2xl font-semibold tracking-tight text-[#0B2E4F]">
              Create your account
            </h1>
            <p class="mt-2 text-sm leading-relaxed text-[#6B7280]">
              Already registered?
              <.link
                navigate={~p"/users/log-in"}
                class="font-medium text-[#1769AA] hover:text-[#0B2E4F] hover:underline"
              >
                Log in
              </.link>
              to your account now.
            </p>
          </div>

          <div class="mt-8 rounded-xl border border-[#E5E7EB] bg-white p-8 shadow-sm">
            <.form
              for={@form}
              id="registration_form"
              phx-submit="save"
              phx-change="validate"
              class="space-y-5"
            >
              <div class="grid grid-cols-2 gap-4">
                <.input
                  field={@form[:first_name]}
                  type="text"
                  label="First name"
                  autocomplete="given-name"
                  required
                  phx-mounted={JS.focus()}
                />
                <.input
                  field={@form[:last_name]}
                  type="text"
                  label="Last name"
                  autocomplete="family-name"
                  required
                />
              </div>

              <.input
                field={@form[:email]}
                type="email"
                label="Email"
                autocomplete="username"
                spellcheck="false"
                required
              />

              <.input
                field={@form[:password]}
                type="password"
                label="Password"
                autocomplete="new-password"
                spellcheck="false"
                required
              />

              <button
                type="submit"
                phx-disable-with="Creating account..."
                class="inline-flex w-full items-center justify-center rounded-md bg-[#1769AA] px-6 py-3 text-sm font-medium text-white transition-colors hover:bg-[#0B2E4F] disabled:cursor-not-allowed disabled:opacity-70"
              >
                Create an account
              </button>
            </.form>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, %{assigns: %{current_scope: %{user: user}}} = socket)
      when not is_nil(user) do
    {:ok, redirect(socket, to: OpenforumWeb.UserAuth.signed_in_path(socket))}
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{}, %{}, validate_unique: false)

    {:ok, assign_form(socket, changeset), temporary_assigns: [form: nil]}
  end

  @impl true
  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_login_instructions(user, &url(~p"/users/log-in/#{&1}"))

        {:noreply,
         socket
         |> put_flash(
           :info,
           "Account created! Check #{user.email} for a confirmation link, or log in with your password."
         )
         |> push_navigate(to: ~p"/users/log-in")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params, validate_unique: false)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")
    assign(socket, form: form)
  end
end
