defmodule OpenforumWeb.Auth.WorkingAreas.FormComponent do
  use OpenforumWeb, :live_component

  alias Openforum.Context.WorkingAreas

  @impl true
  def update(%{working_area: working_area} = assigns, socket) do
    changeset = WorkingAreas.change_working_area(working_area)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:form, to_form(changeset))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-lg font-semibold tracking-tight text-[#0B2E4F]">{@title}</h2>

      <.form
        for={@form}
        id="working-area-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        class="mt-5 space-y-5"
      >

        <div class="grid grid-cols-2 gap-4">
          <.input field={@form[:name]} type="text" label="Name" />
        </div>

        <.input field={@form[:description]} type="text" label="Description" />
        <.input
          field={@form[:area_lead_id]}
          type="select"
          label="Area Lead"
          options={@area_leads |> Enum.map(&{&1.name, &1.id})}
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
  def handle_event("validate", %{"working_area" => working_area_params}, socket) do
    changeset =
      socket.assigns.working_area
      |> WorkingAreas.change_working_area(working_area_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("save", %{"working_area" => working_area_params}, socket) do
    save_working_area(socket, socket.assigns.action, working_area_params)
  end

  def handle_event("cancel", _params, socket) do
    send(self(), {__MODULE__, {:cancelled, nil}})
    {:noreply, socket}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :image, ref)}
  end

  defp save_working_area(socket, :new, working_area_params) do
    case WorkingAreas.create_working_area(working_area_params) do
      {:ok, working_area} ->
        notify_parent({:saved, working_area})

        {:noreply,
         socket
         |> put_flash(:info, "Working area created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_working_area(socket, :edit, working_area_params) do
    case WorkingAreas.update_working_area(socket.assigns.working_area, working_area_params) do
      {:ok, working_area} ->
        notify_parent({:saved, working_area})

        {:noreply,
         socket
         |> put_flash(:info, "Working area updated successfully")
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
