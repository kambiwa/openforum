defmodule OpenforumWeb.UserLive.Login do
  use OpenforumWeb, :live_view

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
              Sign in to continue
            </h1>
            <p class="mt-2 text-sm leading-relaxed text-[#6B7280]">
              <%= if @current_scope do %>
                You need to reauthenticate to perform sensitive actions on your account.
              <% else %>
                Don't have an account?
                <.link
                  navigate={~p"/users/register"}
                  class="font-medium text-[#1769AA] hover:text-[#0B2E4F] hover:underline"
                >
                  Sign up
                </.link>
                to get started.
              <% end %>
            </p>
          </div>

          <div class="mt-8 rounded-xl border border-[#E5E7EB] bg-white p-8 shadow-sm">
            <.form
              :let={f}
              for={@form}
              id="login_form_password"
              action={~p"/users/log-in"}
              phx-submit="submit_password"
              phx-trigger-action={@trigger_submit}
              class="space-y-5"
            >
              <.input
                readonly={!!@current_scope}
                field={f[:email]}
                type="email"
                label="Email"
                autocomplete="username"
                spellcheck="false"
                required
                phx-mounted={JS.focus()}
              />
              <.input
                field={@form[:password]}
                type="password"
                label="Password"
                autocomplete="current-password"
                spellcheck="false"
              />

              <div class="space-y-3 pt-1">
                <button
                  type="submit"
                  name={@form[:remember_me].name}
                  value="true"
                  class="inline-flex w-full items-center justify-center rounded-md bg-[#1769AA] px-6 py-3 text-sm font-medium text-white transition-colors hover:bg-[#0B2E4F]"
                >
                  Log in and stay logged in <span class="ml-1" aria-hidden="true">→</span>
                </button>
                <button
                  type="submit"
                  class="inline-flex w-full items-center justify-center rounded-md border border-[#4F7FA8]/40 bg-white px-6 py-3 text-sm font-medium text-[#0B2E4F] transition-colors hover:bg-[#EAF3F8]"
                >
                  Log in only this time
                </button>
              </div>
            </.form>
          </div>

          <p class="mt-6 text-center text-xs text-[#6B7280]">
            <.link
              navigate={~p"/users/reset-password"}
              class="font-medium text-[#1769AA] hover:text-[#0B2E4F] hover:underline"
            >
              Forgot your password?
            </.link>
          </p>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    email =
      Phoenix.Flash.get(socket.assigns.flash, :email) ||
        get_in(socket.assigns, [:current_scope, Access.key(:user), Access.key(:email)])

    form = to_form(%{"email" => email}, as: "user")

    {:ok, assign(socket, form: form, trigger_submit: false)}
  end

  @impl true
  def handle_event("submit_password", _params, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end
end
