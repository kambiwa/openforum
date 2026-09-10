defmodule OpenforumWeb.Auth.WorkFlowSteps.StepFormComponent do
  use OpenforumWeb, :live_component

  alias Openforum.Context.WorkFlowSteps

  @impl true
  def update(%{step: step} = assigns, socket) do
    changeset = WorkFlowSteps.change_step(step)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:stage_options, WorkFlowSteps.stage_options())
     |> assign(:role_options, WorkFlowSteps.list_roles_for_select())
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"work_flow_step" => params}, socket) do
    changeset =
      socket.assigns.step
      |> WorkFlowSteps.change_step(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"work_flow_step" => params}, socket) do
    save_step(socket, params)
  end

  def handle_event("cancel", _params, socket) do
    notify_parent({:cancelled, socket.assigns.step})
    {:noreply, socket}
  end

  defp save_step(socket, params) do
    work_flow_id = socket.assigns.work_flow.id

    result =
      if socket.assigns.step.id do
        WorkFlowSteps.update_step(socket.assigns.step, params)
      else
        WorkFlowSteps.create_step(work_flow_id, params)
      end

    case result do
      {:ok, step} ->
        notify_parent({:saved, step})
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, changeset), do: assign(socket, :form, to_form(changeset))
  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h4 class="mb-3 text-sm font-semibold text-[#0B2E4F]">
        {if @action == :edit, do: "Edit Step", else: "New Step"}
      </h4>

      <.form
        for={@form}
        id="step-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        class="space-y-3"
      >
        <.input field={@form[:name]} type="text" label="Name" placeholder="e.g. Editorial Review" required />

        <.input field={@form[:description]} type="textarea" label="Description" placeholder="Optional description..." />

        <.input
          field={@form[:stage_type]}
          type="select"
          label="Stage"
          options={@stage_options}
          prompt="Select stage"
          required
        />

        <.input
          field={@form[:role_id]}
          type="select"
          label="Role"
          options={@role_options}
          prompt="Select the role that acts on this step"
          required
        />

        <.input field={@form[:action]} type="textarea" label="Action" placeholder="What should happen at this step..." />

        <div class="flex items-center justify-end gap-3 pt-2">
          <button type="button" phx-click="cancel" phx-target={@myself}
            class="rounded-lg border border-[#E5E7EB] bg-white px-4 py-2 text-sm font-medium text-[#0B2E4F] hover:bg-[#F9FAFB]">
            Cancel
          </button>
          <button type="submit" phx-disable-with="Saving..."
            class="rounded-lg bg-[#1769AA] px-4 py-2 text-sm font-medium text-white hover:bg-[#0B2E4F]">
            Save Step
          </button>
        </div>
      </.form>
    </div>
    """
  end
end
