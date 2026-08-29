# defmodule OpenforumWeb.JobType.FormComponent do
#   use OpenforumWeb, :live_component

#   alias OpenforumWeb.Context.CxtJobType
#   alias EnrouteHaye.Repo
#   alias EnrouteHaye.Schema.{Department, JobType}

#   import Ecto.Query

#   @impl true
#   def update(%{job_type: job_type} = assigns, socket) do
#     changeset = CxtJobType.change_job_type(job_type)
#     departments = Repo.all(from d in Department, order_by: d.name)
#     job_types = Repo.all(from t in JobType, order_by: t.title)

#     {:ok,
#      socket
#      |> assign(assigns)
#      |> assign(:departments, departments)
#      |> assign(:job_types, job_types)
#      |> assign(:form, to_form(changeset))}
#   end

#   @impl true
#   def render(assigns) do
#     ~H"""
#     <div style="background: #fff; border-radius: 0.75rem; width: 100%; box-sizing: border-box; font-family: 'Inter', sans-serif;">

#       <%!-- ══ HEADER ══ --%>
#       <div style="background: #8B1A1A; border-radius: 0.75rem 0.75rem 0 0;
#                   padding: 1rem 1.5rem; display: flex; align-items: center; gap: 0.6rem;">
#         <div style="width: 2rem; height: 2rem; background: rgba(255,255,255,0.15);
#                     border-radius: 0.4rem; display: flex; align-items: center; justify-content: center;">
#           <.icon name="hero-cake" style="width: 1rem; height: 1rem; color: #fff;" />
#         </div>
#         <div>
#           <h2 style="font-size: 0.92rem; font-weight: 600; color: #fff; margin: 0;">{@title}</h2>
#           <p style="font-size: 0.72rem; color: rgba(255,255,255,0.65); margin: 0;">
#             Fill in the details below to {if @action == :new, do: "create a new job item", else: "update the job item"}.
#           </p>
#         </div>
#       </div>

#       <.form
#         for={@form}
#         phx-target={@myself}
#         phx-change="validate"
#         phx-submit="save"
#         style="padding: 1.25rem; width: 100%; box-sizing: border-box; overflow: hidden;"
#       >
#         <%!-- ══ Section: Job Info ══ --%>
#         <div>
#           <p style="font-size: 0.7rem; font-weight: 700; color: #8B1A1A;
#                     text-transform: uppercase; letter-spacing: 0.1em; margin-bottom: 0.75rem;
#                     display: flex; align-items: center; gap: 0.4rem;">
#             <span style="display: inline-block; width: 2rem; height: 1px; background: #8B1A1A;"></span>
#             Job Info
#           </p>
#           <div style="display: grid; grid-template-columns: 1fr; gap: 0.75rem;">
#             <.input
#               field={@form[:title]}
#               label="Job Title"
#             />
#             <.input
#               type="textarea"
#               field={@form[:description]}
#               label="Description"
#               style="min-height: 80px; resize: vertical;"
#             />
#           </div>
#         </div>

#         <%!-- ══ ACTIONS ══ --%>
#         <div style="margin-top: 1.5rem; padding-top: 1rem; border-top: 1px solid #E8E2D9;
#                     display: flex; justify-content: flex-end; gap: 0.5rem;">
#           <button
#             type="button"
#             phx-click="close"
#             phx-target={@myself}
#             style="padding: 0.5rem 1.1rem; font-size: 0.82rem; border-radius: 0.5rem;
#                    border: 1px solid #E8E2D9; background: #fff; cursor: pointer; color: #374151;"
#           >
#             Cancel
#           </button>
#           <button
#             type="submit"
#             style="padding: 0.5rem 1.25rem; font-size: 0.82rem; border-radius: 0.5rem;
#                    border: none; background: #8B1A1A; color: #fff; cursor: pointer;
#                    display: inline-flex; align-items: center; gap: 0.35rem;"
#           >
#             <.icon name="hero-check" style="width: 0.85rem; height: 0.85rem;" />
#             {if @action == :new, do: "Create Job", else: "Save Changes"}
#           </button>
#         </div>
#       </.form>
#     </div>
#     """
#   end

#   @impl true
#   def handle_event("validate", %{"job_type" => params}, socket) do
#     changeset =
#       socket.assigns.job_type
#       |> CxtJobType.change_job_type(params)
#       |> Map.put(:action, :validate)

#     {:noreply, assign(socket, form: to_form(changeset))}
#   end

#   @impl true
#   def handle_event("save", %{"job_type" => params}, socket) do
#     case socket.assigns.action do
#       :new -> create_job_type(socket, params)
#       :edit -> update_job_type(socket, params)
#     end
#   end

#   defp create_job_type(socket, params) do
#     case CxtJobType.create_job_type(params) do
#       {:ok, job_type} ->
#         notify_parent({:saved, job_type})

#         {:noreply,
#          socket
#          |> put_flash(:info, "Job type created successfully")
#          |> push_patch(to: socket.assigns.patch)}

#       {:error, changeset} ->
#         {:noreply, assign(socket, form: to_form(changeset))}
#     end
#   end

#   defp update_job_type(socket, params) do
#     case CxtJobType.update_job_type(socket.assigns.job_type, params) do
#       {:ok, job_type} ->
#         notify_parent({:saved, job_type})

#         {:noreply,
#          socket
#          |> put_flash(:info, "Job type updated successfully")
#          |> push_patch(to: socket.assigns.patch)}

#       {:error, changeset} ->
#         {:noreply, assign(socket, form: to_form(changeset))}
#     end
#   end

#   defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
# end
