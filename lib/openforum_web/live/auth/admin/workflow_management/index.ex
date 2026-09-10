defmodule OpenforumWeb.Auth.WorkFlowLive.Index do
  use OpenforumWeb, :live_view

  alias OpenforumWeb.PaginationComponent
  alias Openforum.Context.WorkFlowSteps
  alias OpenforumWeb.Datatable.Table
  alias OpenforumWeb.Pagination
  alias Openforum.WorkFlowStep
  alias Openforum.WorkFlow

  @status_options [{"Active", "active"}, {"Draft", "draft"}, {"Inactive", "inactive"}]

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Workflows")
      |> assign(:data_loader, false)
      |> assign(:data, [])
      |> assign(:data_pagenations, %{})
      |> assign(:usage_counts, %{})
      |> assign(filter_expanded: false)
      |> assign(:status_filter, "")
      |> assign(:search_filter, "")
      |> assign(:work_flow, %WorkFlow{})
      |> assign(:status_options, @status_options)
      |> assign(:steps, [])
      |> assign(:step, nil)
      |> Pagination.order_by_composer()
      |> Pagination.i_search_composer()

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply,
     socket
     |> assign(:params, params)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Workflow")
    |> assign(:work_flow, WorkFlowSteps.get_work_flow!(id))
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    socket
    |> assign(:page_title, "View Workflow")
    |> assign(:work_flow, WorkFlowSteps.get_work_flow!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Workflow")
    |> assign(:work_flow, %WorkFlow{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Workflows")
    |> assign(:work_flow, nil)
    |> assign(:step, nil)
    |> fetch_filtered_work_flows()
  end

  defp apply_action(socket, :steps, _params) do
    # live_action :steps is normally set via handle_event("manage_steps")
    # or automatically after creating a new workflow (see handle_info below).
    socket
  end

  # ── Workflow FormComponent messages ─────────────────────────────────

  @impl true
  def handle_info({OpenforumWeb.Auth.WorkFlowSteps.FormComponent, {:saved, work_flow}}, socket) do
    case socket.assigns.live_action do
      :new ->
        # Fresh workflow just created — jump straight into Manage Steps so
        # the admin can add steps + approvers without hunting for the row.
        {:noreply,
         socket
         |> put_flash(:info, "\"#{work_flow.name}\" created. Now add its steps.")
         |> assign(:page_title, "Manage Steps — #{work_flow.name}")
         |> assign(:work_flow, work_flow)
         |> assign(:steps, WorkFlowSteps.list_steps(work_flow.id))
         |> assign(:step, nil)
         |> assign(:live_action, :steps)}

      _ ->
        {:noreply,
         socket
         |> assign(:live_action, :index)
         |> fetch_filtered_work_flows()}
    end
  end

  def handle_info({OpenforumWeb.Auth.WorkFlowSteps.FormComponent, {:cancelled, _}}, socket) do
    {:noreply, assign(socket, :live_action, :index)}
  end

  # ── Step FormComponent messages ─────────────────────────────────────

  def handle_info({OpenforumWeb.Auth.WorkFlowSteps.StepFormComponent, {:saved, _step}}, socket) do
    {:noreply,
     socket
     |> assign(:step, nil)
     |> assign(:steps, WorkFlowSteps.list_steps(socket.assigns.work_flow.id))}
  end

  def handle_info({OpenforumWeb.Auth.WorkFlowSteps.StepFormComponent, {:cancelled, _}}, socket) do
    {:noreply, assign(socket, :step, nil)}
  end

  # ── Workflow row actions ────────────────────────────────────────────

  @impl true
  def handle_event("add_work_flow", _params, socket) do
    {:noreply,
     socket
     |> assign(:page_title, "New Workflow")
     |> assign(:work_flow, %WorkFlow{})
     |> assign(:live_action, :new)}
  end

  def handle_event("edit", %{"id" => id}, socket) do
    {:noreply,
     socket
     |> assign(:page_title, "Edit Workflow")
     |> assign(:work_flow, WorkFlowSteps.get_work_flow!(id))
     |> assign(:live_action, :edit)}
  end

  def handle_event("view", %{"id" => id}, socket) do
    {:noreply,
     socket
     |> assign(:page_title, "View Workflow")
     |> assign(:work_flow, WorkFlowSteps.get_work_flow!(id))
     |> assign(:live_action, :show)}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    work_flow = WorkFlowSteps.get_work_flow!(id)

    case WorkFlowSteps.delete_work_flow(work_flow) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "\"#{work_flow.name}\" deleted.")
         |> fetch_filtered_work_flows()}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not delete \"#{work_flow.name}\".")}
    end
  end

  def handle_event("close", _params, socket) do
    {:noreply,
     socket
     |> assign(:live_action, :index)
     |> assign(:step, nil)
     |> fetch_filtered_work_flows()}
  end

  # ── Manage Steps panel ──────────────────────────────────────────────

  def handle_event("manage_steps", %{"id" => id}, socket) do
    work_flow = WorkFlowSteps.get_work_flow!(id)

    {:noreply,
     socket
     |> assign(:page_title, "Manage Steps — #{work_flow.name}")
     |> assign(:work_flow, work_flow)
     |> assign(:steps, WorkFlowSteps.list_steps(work_flow.id))
     |> assign(:step, nil)
     |> assign(:live_action, :steps)}
  end

  def handle_event("add_step", _params, socket) do
    IO.inspect(socket, label: "============0909")
    {:noreply, assign(socket, :step, %WorkFlowStep{})}
  end

  def handle_event("edit_step", %{"id" => id}, socket) do
    {:noreply, assign(socket, :step, WorkFlowSteps.get_step!(id))}
  end

  def handle_event("cancel_step_form", _params, socket) do
    {:noreply, assign(socket, :step, nil)}
  end

  def handle_event("delete_step", %{"id" => id}, socket) do
    step = WorkFlowSteps.get_step!(id)

    case WorkFlowSteps.delete_step(step) do
      {:ok, _} ->
        {:noreply, assign(socket, :steps, WorkFlowSteps.list_steps(socket.assigns.work_flow.id))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not delete \"#{step.name}\".")}
    end
  end

  # ── Filters ─────────────────────────────────────────────────────────

  def handle_event("toggle-filter", _, socket) do
    {:noreply, assign(socket, filter_expanded: !socket.assigns.filter_expanded)}
  end

  def handle_event("filter", %{"filter" => filters}, socket) do
    {:noreply,
     socket
     |> assign(:status_filter, filters["status_filter"] || "")
     |> assign(:search_filter, filters["search_filter"] || "")
     |> fetch_filtered_work_flows()}
  end

  # ── Data loading ────────────────────────────────────────────────────

  defp fetch_filtered_work_flows(socket) do
    filters = %{
      search_filter: socket.assigns.search_filter,
      status_filter: socket.assigns.status_filter
    }

    data =
      WorkFlowSteps.list_work_flows(
        Pagination.create_table_params(socket, socket.assigns.params),
        filters
      )

    ids = Enum.map(data.entries, & &1.id)

    socket
    |> assign(:data, data.entries)
    |> assign(:data_pagenations, Map.drop(data, [:entries]))
    |> assign(:usage_counts, WorkFlowSteps.usage_counts(ids))
    |> assign(:data_loader, false)
  end

  # ── Display helpers ─────────────────────────────────────────────────

  defp confirm_text(work_flow, usage_counts) do
    case Map.get(usage_counts, work_flow.id, 0) do
      0 -> "Delete \"#{work_flow.name}\"? This cannot be undone."
      n -> "\"#{work_flow.name}\" is used by #{n} content item(s). Delete anyway?"
    end
  end

  attr :status, :string, required: true

  defp status_badge(assigns) do
    ~H"""
    <span class={[
      "inline-flex items-center rounded-md px-2.5 py-1 text-xs font-medium capitalize",
      status_classes(@status)
    ]}>
      {@status}
    </span>
    """
  end

  defp status_classes("active"), do: "bg-[#EAF9F0] text-[#1E8E5A]"
  defp status_classes("draft"), do: "bg-[#FEF6E7] text-[#B7791F]"
  defp status_classes("inactive"), do: "bg-[#F3F4F6] text-[#6B7280]"
  defp status_classes(_), do: "bg-[#F3F4F6] text-[#6B7280]"

  attr :stage_type, :atom, required: true

  defp stage_badge(assigns) do
    ~H"""
    <span class={[
      "inline-flex items-center rounded-md px-2 py-0.5 text-[0.65rem] font-medium capitalize",
      stage_classes(@stage_type)
    ]}>
      {@stage_type}
    </span>
    """
  end

  defp stage_classes(:draft), do: "bg-[#FEF6E7] text-[#B7791F]"
  defp stage_classes(:reviewer), do: "bg-[#EAF3F8] text-[#1769AA]"
  defp stage_classes(:approver), do: "bg-[#EAF9F0] text-[#1E8E5A]"
  defp stage_classes(_), do: "bg-[#F3F4F6] text-[#6B7280]"

  attr :work_flow, WorkFlow, required: true

  defp steps_badge(assigns) do
    count = WorkFlowSteps.step_count(assigns.work_flow)

    ~H"""
    <span class="inline-flex items-center rounded-full bg-[#EAF3F8] px-2.5 py-1 text-xs font-medium text-[#1769AA]">
      {count} {if count == 1, do: "step", else: "steps"}
    </span>
    """
  end

  # ── Render ──────────────────────────────────────────────────────────

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.admin_app flash={@flash} current_scope={@current_scope} current_page={:work_flows}>
      <div class="flex flex-col gap-6 p-6">
        <%!-- PAGE HEADER --%>
        <div class="flex items-center justify-between">
          <div>
            <h1 class="mb-0.5 text-[1.1rem] font-bold text-[#0B2E4F]">
              Workflow Management
            </h1>
            <p class="text-[0.82rem] text-[#6B7280]">
              Manage content approval workflows and their steps.
            </p>
          </div>

          <div class="flex items-center gap-3">
            <button
              phx-click="toggle-filter"
              class="inline-flex items-center gap-1.5 rounded-lg border border-[#E5E7EB] bg-white px-4 py-2 text-[0.82rem] font-medium text-[#0B2E4F] transition-colors hover:bg-[#EAF3F8]"
            >
              <.icon name="hero-funnel" class="size-4" /> Filter
            </button>

            <button
              phx-click="add_work_flow"
              class="inline-flex items-center gap-1.5 rounded-lg bg-[#1769AA] px-4 py-2 text-[0.82rem] font-medium text-white transition-colors hover:bg-[#0B2E4F]"
            >
              <.icon name="hero-plus" class="size-4" /> New Workflow
            </button>
          </div>
        </div>

        <%!-- FILTER PANEL --%>
        <div
          :if={@filter_expanded}
          class="rounded-xl border border-[#E5E7EB] border-t-[3px] border-t-[#1769AA] bg-white p-5"
        >
          <p class="mb-4 text-xs font-semibold uppercase tracking-[0.08em] text-[#0B2E4F]">
            Filters
          </p>
          <.form for={%{}} as={:filter} phx-change="filter">
            <div class="grid grid-cols-3 gap-4">
              <div class="flex flex-col gap-1.5">
                <label class="text-xs font-medium text-[#0B2E4F]">Search</label>
                <.input
                  name="filter[search_filter]"
                  placeholder="Search workflows..."
                  value={@search_filter}
                />
              </div>

              <div class="flex flex-col gap-1.5">
                <label class="text-xs font-medium text-[#0B2E4F]">Status</label>
                <.input
                  type="select"
                  name="filter[status_filter]"
                  prompt="All"
                  options={@status_options}
                  value={@status_filter}
                />
              </div>
            </div>
          </.form>
        </div>

        <%!-- TABLE --%>
        <div class="overflow-hidden rounded-xl border border-[#E5E7EB] bg-white">
          <div class="border-b border-[#E5E7EB] px-5 py-4">
            <h2 class="text-[0.85rem] font-semibold text-[#0B2E4F]">All Workflows</h2>
          </div>

          <Table.table id="tbl_work_flows" rows={@data}>
            <:col :let={work_flow} label="Name">
              <span class="font-medium text-[#252525]">{work_flow.name}</span>
            </:col>

            <:col :let={work_flow} label="Status">
              <.status_badge status={work_flow.status} />
            </:col>

            <:col :let={work_flow} label="Steps">
              <.steps_badge work_flow={work_flow} />
            </:col>

            <:col :let={work_flow} label="Description">
              <span class="text-[#6B7280]">{work_flow.description}</span>
            </:col>

            <:action :let={work_flow}>
              <button
                phx-click="manage_steps"
                phx-value-id={work_flow.id}
                title="Manage Steps"
                class="inline-flex items-center gap-1 rounded-md bg-[#F3F4F6] px-2.5 py-1 text-xs font-medium text-[#0B2E4F] transition-colors hover:bg-[#E5E7EB]"
              >
                <.icon name="hero-list-bullet" class="size-3" /> Steps
              </button>

              <button
                phx-click="view"
                phx-value-id={work_flow.id}
                title="View"
                class="inline-flex items-center gap-1 rounded-md bg-[#F3F4F6] px-2.5 py-1 text-xs font-medium text-[#6B7280] transition-colors hover:bg-[#E5E7EB]"
              >
                <.icon name="hero-eye" class="size-3" /> View
              </button>

              <button
                phx-click="edit"
                phx-value-id={work_flow.id}
                title="Edit"
                class="inline-flex items-center gap-1 rounded-md bg-[#EAF3F8] px-2.5 py-1 text-xs font-medium text-[#1769AA] transition-colors hover:bg-[#4F7FA8]/20"
              >
                <.icon name="hero-pencil-square" class="size-3" /> Edit
              </button>

              <button
                phx-click="delete"
                phx-value-id={work_flow.id}
                data-confirm={confirm_text(work_flow, @usage_counts)}
                title="Delete"
                class="inline-flex items-center gap-1 rounded-md bg-red-50 px-2.5 py-1 text-xs font-medium text-red-600 transition-colors hover:bg-red-100"
              >
                <.icon name="hero-trash" class="size-3" /> Delete
              </button>
            </:action>
          </Table.table>

          <div :if={@data_loader} class="p-10 text-center">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="mx-auto size-8 animate-spin text-[#1769AA]"
              fill="none"
              viewBox="0 0 24 24"
            >
              <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
              <path
                class="opacity-75"
                fill="currentColor"
                d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
              />
            </svg>
          </div>

          <div class="border-t border-[#E5E7EB]">
            <.live_component
              module={PaginationComponent}
              id="PaginationComponent"
              params={@params}
              pagination_data={@data_pagenations}
            />
          </div>
        </div>

        <%!-- WORKFLOW MODAL (new / edit / show) --%>
        <.modal
          :if={@live_action in [:new, :edit, :show]}
          id={"crud-work-flow-modal-#{(@work_flow && @work_flow.id) || :new}"}
          show
          on_cancel={JS.push("close")}
        >
          <.live_component
            module={OpenforumWeb.Auth.WorkFlowSteps.FormComponent}
            id={(@work_flow && @work_flow.id) || :new}
            title={@page_title}
            action={@live_action}
            work_flow={@work_flow}
            patch={~p"/admin/work_flows"}
          />
        </.modal>

        <%!-- MANAGE STEPS MODAL --%>
        <.modal
          :if={@live_action == :steps}
          id="manage-steps-modal"
          show
          on_cancel={JS.push("close")}
        >
          <div class="flex flex-col gap-4">
            <div class="flex items-center justify-between">
              <div>
                <h2 class="text-base font-bold text-[#0B2E4F]">
                  Steps — {@work_flow.name}
                </h2>
                <p class="text-xs text-[#6B7280]">
                  Add or remove approval steps for this workflow. Order follows
                  Draft → Reviewer → Approver automatically.
                </p>
              </div>

              <button
                phx-click="add_step"
                class="inline-flex items-center gap-1.5 rounded-lg bg-[#1769AA] px-3 py-1.5 text-xs font-medium text-white hover:bg-[#0B2E4F]"
              >
                <.icon name="hero-plus" class="size-3" /> Add Step
              </button>
            </div>

            <ol id="steps-list" class="flex flex-col gap-2">
              <li
                :for={step <- @steps}
                id={"step-#{step.id}"}
                class="flex items-center justify-between rounded-lg border border-[#E5E7EB] p-3"
              >
                <div class="flex flex-col gap-1">
                  <div class="flex items-center gap-2">
                    <.stage_badge stage_type={step.stage_type} />
                    <span class="font-medium text-[#252525]">{step.name}</span>
                  </div>
                  <span :if={step.role} class="text-xs text-[#6B7280]">
                    Approver role: {step.role.name}
                  </span>
                  <span :if={step.action not in [nil, ""]} class="text-xs text-[#6B7280]">
                    Action: {step.action}
                  </span>
                </div>

                <div class="flex gap-2">
                  <button
                    phx-click="edit_step"
                    phx-value-id={step.id}
                    class="text-xs font-medium text-[#1769AA] hover:underline"
                  >
                    Edit
                  </button>
                  <button
                    phx-click="delete_step"
                    phx-value-id={step.id}
                    data-confirm={"Remove \"#{step.name}\"?"}
                    class="text-xs font-medium text-red-600 hover:underline"
                  >
                    Delete
                  </button>
                </div>
              </li>
            </ol>

            <p :if={@steps == []} class="py-6 text-center text-sm text-[#6B7280]">
              No steps yet — add the first one above.
            </p>

            <div :if={@step} class="rounded-lg border border-[#E5E7EB] bg-[#F9FAFB] p-4">
              <.live_component
                module={OpenforumWeb.Auth.WorkFlowSteps.StepFormComponent}
                id={@step.id || :new_step}
                action={if @step.id, do: :edit, else: :new}
                step={@step}
                work_flow={@work_flow}
              />
            </div>
          </div>
        </.modal>
      </div>
    </Layouts.admin_app>
    """
  end
end
