defmodule OpenforumWeb.Auth.Users.FormComponet do
  use OpenforumWeb, :live_component

  alias Openforum.Accounts

  @impl true
  def update(%{user: users} = assigns, socket) do
    changeset = Accounts.change_user_registration(users)

    {:ok,
     socket
     |> assign(assigns)
     |> allow_upload(:image,
       accept: ~w(.jpg .jpeg .png .webp),
       max_entries: 1,
       max_file_size: 5_000_000
     )
     |> assign(:form, to_form(changeset))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-lg font-semibold tracking-tight text-[#0B2E4F]">{@title}</h2>

      <.form
        for={@form}
        id="user-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        class="mt-5 space-y-5"
      >
        <%!-- Avatar upload --%>
        <div class="flex flex-col gap-1.5">
          <label class="text-xs font-medium text-[#0B2E4F]">Photo</label>
          <div
            class="flex items-center gap-4 rounded-lg border border-dashed border-[#4F7FA8]/40 bg-[#F4F8FB] px-4 py-4"
            phx-drop-target={@uploads.image.ref}
          >
            <div class="flex h-14 w-14 shrink-0 items-center justify-center overflow-hidden rounded-full bg-[#EAF3F8]">
              <.icon name="hero-user" class="size-6 text-[#4F7FA8]" />
            </div>
            <div class="min-w-0 flex-1">
              <label
                for={@uploads.image.ref}
                class="inline-flex cursor-pointer items-center gap-1.5 rounded-md border border-[#4F7FA8]/40 bg-white px-3 py-1.5 text-xs font-medium text-[#0B2E4F] transition-colors hover:bg-[#EAF3F8]"
              >
                <.icon name="hero-arrow-up-tray" class="size-3.5" /> Upload Profile photo
              </label>
              <.live_file_input upload={@uploads.image} class="sr-only" />
              <p class="mt-1.5 text-[0.68rem] text-[#6B7280]">JPG, PNG or WEBP. Max 5MB.</p>
            </div>
          </div>

          <div
            :for={entry <- @uploads.image.entries}
            class="flex items-center gap-2 text-xs text-[#6B7280]"
          >
            <.icon name="hero-photo" class="size-3.5 text-[#1769AA]" />
            <span class="truncate">{entry.client_name}</span>
            <progress value={entry.progress} max="100" class="h-1 w-24 accent-[#1769AA]">{entry.progress}%</progress>
            <button
              type="button"
              phx-click="cancel-upload"
              phx-value-ref={entry.ref}
              phx-target={@myself}
              class="text-[#6B7280] hover:text-red-600"
              aria-label="Remove photo"
            >
              <.icon name="hero-x-mark" class="size-3.5" />
            </button>
            <p :for={err <- upload_errors(@uploads.image, entry)} class="text-red-600">
              {error_to_string(err)}
            </p>
          </div>
        </div>

        <div class="grid grid-cols-2 gap-4">
          <.input field={@form[:first_name]} type="text" label="First Name" />
          <.input field={@form[:last_name]} type="text" label="Last Name" />
        </div>

        <.input field={@form[:email]} type="email" label="Email" />
        <.input field={@form[:password]} type="password" label="Password" />
        <.input
          field={@form[:role]}
          type="select"
          label="Role"
          options={[{"Admin", "admin"}, {"User", "user"}]}
        />

        <div class="flex justify-end gap-2 border-t border-[#E5E7EB] pt-5">
          <.button
            type="button"
            phx-click={JS.push("cancel", target: @myself)}
            class="inline-flex items-center justify-center rounded-md border border-[#4F7FA8]/40 bg-white px-5 py-2.5 text-sm font-medium text-[#0B2E4F] transition-colors hover:bg-[#EAF3F8]"
          >
            Cancel
          </.button>
          <.button
            type="submit"
            phx-disable-with="Saving..."
            class="inline-flex items-center justify-center rounded-md bg-[#1769AA] px-5 py-2.5 text-sm font-medium text-white transition-colors hover:bg-[#0B2E4F]"
          >
            Save
          </.button>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      socket.assigns.user
      |> Accounts.change_user_registration(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    save_user(socket, socket.assigns.action, user_params)
  end

  def handle_event("cancel", _params, socket) do
    send(self(), {__MODULE__, {:cancelled, nil}})
    {:noreply, socket}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :image, ref)}
  end

  defp save_user(socket, :new, user_params) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        notify_parent({:saved, user})

        {:noreply,
         socket
         |> put_flash(:info, "User created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_user(socket, :edit, user_params) do
    case Accounts.update_user(socket.assigns.user, user_params) do
      {:ok, user} ->
        notify_parent({:saved, user})

        {:noreply,
         socket
         |> put_flash(:info, "User updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp error_to_string(:too_large), do: "File is too large"
  defp error_to_string(:not_accepted), do: "Unsupported file type"
  defp error_to_string(:too_many_files), do: "Only one photo allowed"
  defp error_to_string(_), do: "Upload error"
end
