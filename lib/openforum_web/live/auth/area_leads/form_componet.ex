defmodule OpenforumWeb.Auth.AreaLeads.FormComponent do
  use OpenforumWeb, :live_component

  alias Openforum.Context.AreaLeads

  @impl true
  def update(%{area_lead: area_lead} = assigns, socket) do
    changeset = AreaLeads.change_area_lead(area_lead)

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
          label="Working Area"
          options={Openforum.Context.WorkingAreas.list_working_areas() |> Enum.map(&{&1.name, &1.id})}
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
  def handle_event("validate", %{"area_lead" => area_lead_params}, socket) do
    changeset =
      socket.assigns.area_lead
      |> AreaLeads.change_area_lead(area_lead_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("save", %{"area_lead" => area_lead_params}, socket) do
    save_area_lead(socket, socket.assigns.action, area_lead_params)
  end

  def handle_event("cancel", _params, socket) do
    send(self(), {__MODULE__, {:cancelled, nil}})
    {:noreply, socket}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :image, ref)}
  end

  defp save_area_lead(socket, :new, area_lead_params) do
    case AreaLeads.create_area_lead(area_lead_params) do
      {:ok, area_lead} ->
        notify_parent({:saved, area_lead})

        {:noreply,
         socket
         |> put_flash(:info, "Area lead created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_area_lead(socket, :edit, area_lead_params) do
    case AreaLeads.update_area_lead(socket.assigns.area_lead, area_lead_params) do
      {:ok, area_lead} ->
        notify_parent({:saved, area_lead})

        {:noreply,
         socket
         |> put_flash(:info, "Area lead updated successfully")
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
