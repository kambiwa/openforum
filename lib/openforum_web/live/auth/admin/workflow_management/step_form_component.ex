defmodule OpenforumWeb.Auth.WorkFlowSteps.StepFormComponent do
  use OpenforumWeb, :live_component

  alias Openforum.Context.WorkFlowSteps

  @impl true
  def update(%{step: step} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:role_options, role_options())
     |> assign_new(:form, fn ->
       to_form(WorkFlowSteps.change_step(step))
     end)}
  end

  @impl true
  def handle_event("validate", %{"work_flow_step" => params}, socket) do
    changeset =
      socket.assigns.step
      |> WorkFlowSteps.change_step(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save", %{"work_flow_step" => params}, socket) do
    save_step(socket, socket.assigns.action, params)
  end

  def handle_event("cancel", _params, socket) do
    notify_parent({:cancelled, nil})
    {:noreply, socket}
  end

  defp save_step(socket, :edit, params) do
    case WorkFlowSteps.update_step(socket.assigns.step, params) do
      {:ok, step} ->
        notify_parent({:saved, step})
        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_step(socket, :new, params) do
    case WorkFlowSteps.create_step(socket.assigns.work_flow.id, params) do
      {:ok, step} ->
        notify_parent({:saved, step})
        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp role_options do
    Openforum.Context.Roles.list_roles()
    |> Enum.map(&{&1.name, &1.id})
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h3 class="mb-3 text-sm font-semibold text-[#0B2E4F]">
        {if @action == :edit, do: "Edit Step", else: "New Step"}
      </h3>

      <.form
        for={@form}
        id="step-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" required />
        <.input field={@form[:description]} type="textarea" label="Description" />
        <.input
          field={@form[:role_id]}
          type="select"
          label="Role"
          options={@role_options}
          prompt="Select a role"
        />

        <:actions>
          <div class="flex items-center justify-end gap-3">
            <button
              type="button"
              phx-click="cancel"
              phx-target={@myself}
              class="rounded-lg border border-[#E5E7EB] px-3 py-1.5 text-xs font-medium text-[#6B7280] hover:bg-[#F3F4F6]"
            >
              Cancel
            </button>
            <.button phx-disable-with="Saving...">Save Step</.button>
          </div>
        </:actions>
      </.form>
    </div>
    """
  end
end
