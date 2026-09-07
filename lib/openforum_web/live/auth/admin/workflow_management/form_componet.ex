defmodule OpenforumWeb.Auth.WorkFlowSteps.FormComponent do
  use OpenforumWeb, :live_component

  alias Openforum.Context.WorkFlowSteps

  @status_options [{"Active", "active"}, {"Draft", "draft"}, {"Inactive", "inactive"}]

  @impl true
  def update(%{work_flow: work_flow} = assigns, socket) do
    changeset = WorkFlowSteps.change_work_flow(work_flow)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:status_options, @status_options)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"work_flow" => params}, socket) do
    changeset =
      socket.assigns.work_flow
      |> WorkFlowSteps.change_work_flow(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"work_flow" => params}, socket) do
    save_work_flow(socket, socket.assigns.action, params)
  end

  def handle_event("cancel", _params, socket) do
    notify_parent({:cancelled, socket.assigns.work_flow})
    {:noreply, socket}
  end

  # ── Private ──────────────────────────────────────────────────────────

  defp save_work_flow(socket, :edit, params) do
    case WorkFlowSteps.update_work_flow(socket.assigns.work_flow, params) do
      {:ok, work_flow} ->
        notify_parent({:saved, work_flow})
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_work_flow(socket, :new, params) do
    case WorkFlowSteps.create_work_flow(params) do
      {:ok, work_flow} ->
        notify_parent({:saved, work_flow})
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_work_flow(socket, :show, _params), do: {:noreply, socket}

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h3 class="mb-4 text-base font-semibold text-[#0B2E4F]">
        {@title}
      </h3>

      <.form
        for={@form}
        id="work-flow-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        class="space-y-4"
      >
        <.input
          field={@form[:name]}
          type="text"
          label="Name"
          placeholder="e.g. Content Approval"
          disabled={@action == :show}
          required
        />

        <.input
          field={@form[:description]}
          type="textarea"
          label="Description"
          placeholder="Optional description..."
          disabled={@action == :show}
        />

        <.input
          field={@form[:status]}
          type="select"
          label="Status"
          options={@status_options}
          prompt="Select status"
          disabled={@action == :show}
        />

        <div class="flex items-center justify-end gap-3 pt-2">
          <button
            type="button"
            phx-click="cancel"
            phx-target={@myself}
            class="rounded-lg border border-[#E5E7EB] bg-white px-4 py-2 text-sm font-medium text-[#0B2E4F] hover:bg-[#F9FAFB]"
          >
            {if @action == :show, do: "Close", else: "Cancel"}
          </button>

          <button
            :if={@action != :show}
            type="submit"
            phx-disable-with="Saving..."
            class="rounded-lg bg-[#1769AA] px-4 py-2 text-sm font-medium text-white hover:bg-[#0B2E4F]"
          >
            Save Workflow
          </button>
        </div>
      </.form>
    </div>
    """
  end
end
