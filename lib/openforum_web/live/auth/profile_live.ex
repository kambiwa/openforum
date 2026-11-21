defmodule OpenforumWeb.Auth.ProfileLive do
  use OpenforumWeb, :live_view

  alias Openforum.Accounts
  alias Openforum.Repo

  @impl true
  def mount(_params, _session, socket) do
    user = Repo.preload(socket.assigns.current_scope.user, :roles, force: true)
    changeset = Accounts.change_user_profile(user, %{})

    {:ok,
     socket
     |> assign(:page_title, "Profile Settings")
     |> assign(:current_page, :profile)
     |> assign(:user, user)
     |> assign(:form, to_form(changeset))
     |> assign(:current_scope, %{socket.assigns.current_scope | user: user})
     |> allow_upload(:photo,
       accept: ~w(.jpg .jpeg .png .webp),
       max_entries: 1,
       max_file_size: 5_000_000
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.admin_app flash={@flash} current_scope={@current_scope} current_page={@current_page}>
      <div class="mx-auto max-w-5xl space-y-6 p-5 sm:p-8">
        <header>
          <p class="text-xs font-semibold uppercase tracking-[0.16em] text-[#1769AA]">Account</p>
          <h1 class="mt-1 text-2xl font-bold tracking-tight text-[#0B2E4F]">Profile settings</h1>
          <p class="mt-2 text-sm text-[#6B7280]">
            Manage the name and photo shown in OpenForum.
          </p>
        </header>

        <.form
          for={@form}
          id="profile-settings-form"
          phx-change="validate"
          phx-submit="save"
          class="overflow-hidden rounded-2xl border border-[#E5E7EB] bg-white shadow-sm"
        >
          <section class="border-b border-[#E5E7EB] p-6 sm:p-8">
            <h2 class="text-base font-semibold text-[#0B2E4F]">Profile photo</h2>
            <p class="mt-1 text-sm text-[#6B7280]">Use a JPG, PNG, or WEBP image up to 5 MB.</p>

            <div class="mt-6 flex flex-col gap-5 sm:flex-row sm:items-center">
              <div
                class="flex size-24 shrink-0 items-center justify-center overflow-hidden rounded-full bg-[#EAF3F8] ring-4 ring-[#F4F8FB]"
                phx-drop-target={@uploads.photo.ref}
              >
                <img
                  :if={@uploads.photo.entries == [] and @user.avatar_url}
                  src={@user.avatar_url}
                  alt="Profile photo"
                  class="size-full object-cover"
                />
                <.live_img_preview
                  :for={entry <- @uploads.photo.entries}
                  entry={entry}
                  class="size-full object-cover"
                />
                <.icon
                  :if={@uploads.photo.entries == [] and is_nil(@user.avatar_url)}
                  name="hero-user"
                  class="size-10 text-[#4F7FA8]"
                />
              </div>

              <div class="min-w-0 flex-1">
                <label
                  for={@uploads.photo.ref}
                  class="inline-flex cursor-pointer items-center gap-2 rounded-lg bg-[#1769AA] px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-[#0B2E4F]"
                >
                  <.icon name="hero-arrow-up-tray" class="size-4" /> Choose photo
                </label>
                <.live_file_input upload={@uploads.photo} class="sr-only" />

                <button
                  :if={@user.avatar_url}
                  type="button"
                  phx-click="remove_photo"
                  class="ml-3 text-sm font-medium text-rose-600 hover:text-rose-700"
                >
                  Remove photo
                </button>

                <div :for={entry <- @uploads.photo.entries} class="mt-3 max-w-sm">
                  <div class="flex items-center justify-between text-xs text-[#6B7280]">
                    <span class="max-w-[14rem] truncate">{entry.client_name}</span>
                    <span class="flex items-center gap-2">
                      {entry.progress}%
                      <button
                        type="button"
                        phx-click="cancel_photo_upload"
                        phx-value-ref={entry.ref}
                        class="font-medium text-rose-600 hover:text-rose-700"
                      >
                        Cancel
                      </button>
                    </span>
                  </div>
                  <progress
                    value={entry.progress}
                    max="100"
                    class="mt-1 h-1.5 w-full accent-[#1769AA]"
                  >
                    {entry.progress}%
                  </progress>
                  <p
                    :for={error <- upload_errors(@uploads.photo, entry)}
                    class="mt-1 text-xs text-rose-600"
                  >
                    {upload_error(error)}
                  </p>
                </div>

                <p :for={error <- upload_errors(@uploads.photo)} class="mt-2 text-xs text-rose-600">
                  {upload_error(error)}
                </p>
              </div>
            </div>
          </section>

          <section class="space-y-5 p-6 sm:p-8">
            <div>
              <h2 class="text-base font-semibold text-[#0B2E4F]">Personal details</h2>
              <p class="mt-1 text-sm text-[#6B7280]">Your email and roles are managed separately.</p>
            </div>

            <div class="grid gap-5 sm:grid-cols-2">
              <.input
                field={@form[:first_name]}
                type="text"
                label="First name"
                autocomplete="given-name"
              />
              <.input
                field={@form[:last_name]}
                type="text"
                label="Last name"
                autocomplete="family-name"
              />
            </div>

            <div class="rounded-xl bg-[#F7F9FB] p-4">
              <p class="text-xs font-medium uppercase tracking-wide text-[#6B7280]">Email address</p>
              <p class="mt-1 text-sm font-medium text-[#252525]">{@user.email}</p>
            </div>

            <div :if={@user.roles != []} class="flex flex-wrap items-center gap-2">
              <span class="text-xs font-medium uppercase tracking-wide text-[#6B7280]">Roles</span>
              <span
                :for={role <- @user.roles}
                class="rounded-full bg-[#EAF3F8] px-3 py-1 text-xs font-semibold text-[#1769AA]"
              >
                {role.name}
              </span>
            </div>

            <div class="flex justify-end border-t border-[#E5E7EB] pt-5">
              <.button
                id="save-profile-button"
                phx-disable-with="Saving…"
                class="inline-flex items-center gap-2 rounded-lg bg-[#1769AA] px-5 py-2.5 text-sm font-semibold text-white transition hover:bg-[#0B2E4F]"
              >
                <.icon name="hero-check" class="size-4" /> Save profile
              </.button>
            </div>
          </section>
        </.form>
      </div>
    </Layouts.admin_app>
    """
  end

  @impl true
  def handle_event("validate", %{"user" => params}, socket) do
    changeset =
      socket.assigns.user
      |> Accounts.change_user_profile(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("save", %{"user" => params}, socket) do
    changeset = Accounts.change_user_profile(socket.assigns.user, params)

    if changeset.valid? do
      save_profile(socket, params)
    else
      {:noreply, assign(socket, :form, to_form(%{changeset | action: :validate}))}
    end
  end

  def handle_event("remove_photo", _params, socket) do
    case Accounts.update_user_profile(socket.assigns.user, %{avatar_url: nil}) do
      {:ok, user} ->
        user = Repo.preload(user, :roles, force: true)
        scope = %{socket.assigns.current_scope | user: user}

        {:noreply,
         socket
         |> assign(:user, user)
         |> assign(:current_scope, scope)
         |> assign(:form, to_form(Accounts.change_user_profile(user, %{})))
         |> put_flash(:info, "Profile photo removed.")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def handle_event("cancel_photo_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :photo, ref)}
  end

  defp save_profile(socket, params) do
    uploaded_photo =
      consume_uploaded_entries(socket, :photo, fn %{path: temp_path}, entry ->
        extension = Path.extname(entry.client_name) |> String.downcase()

        filename =
          "#{:crypto.strong_rand_bytes(18) |> Base.url_encode64(padding: false)}#{extension}"

        upload_dir =
          Path.join([:code.priv_dir(:openforum), "static", "uploads", "profile-photos"])

        :ok = File.mkdir_p(upload_dir)
        :ok = File.cp(temp_path, Path.join(upload_dir, filename))
        {:ok, "/uploads/profile-photos/#{filename}"}
      end)

    attrs =
      case uploaded_photo do
        [photo_url | _] -> Map.put(params, "avatar_url", photo_url)
        _ -> Map.put(params, "avatar_url", socket.assigns.user.avatar_url)
      end

    case Accounts.update_user_profile(socket.assigns.user, attrs) do
      {:ok, user} ->
        user = Repo.preload(user, :roles, force: true)
        scope = %{socket.assigns.current_scope | user: user}

        {:noreply,
         socket
         |> assign(:user, user)
         |> assign(:current_scope, scope)
         |> assign(:form, to_form(Accounts.change_user_profile(user, %{})))
         |> put_flash(:info, "Profile updated successfully.")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp upload_error(:too_large), do: "Photo must be 5 MB or smaller."
  defp upload_error(:not_accepted), do: "Choose a JPG, PNG, or WEBP image."
  defp upload_error(:too_many_files), do: "Upload one photo at a time."
  defp upload_error(_), do: "The photo could not be uploaded."
end
