# defmodule OpenforumWeb.Departments.FormComponent do
#   use OpenforumWeb, :live_component

#   alias OpenforumWeb.Context.CxtDepartment

#   @impl true
#   def update(%{department: department} = assigns, socket) do
#     changeset = CxtDepartment.change_department(department)

#     {:ok,
#      socket
#      |> assign(assigns)
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
#             Fill in the details below to {if @action == :new, do: "create a new department item", else: "update the department item"}.
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
#         <%!-- ══ Section: Department Info ══ --%>
#         <div>
#           <p style="font-size: 0.7rem; font-weight: 700; color: #8B1A1A;
#                     text-transform: uppercase; letter-spacing: 0.1em; margin-bottom: 0.75rem;
#                     display: flex; align-items: center; gap: 0.4rem;">
#             <span style="display: inline-block; width: 2rem; height: 1px; background: #8B1A1A;"></span>
#             Department Info
#           </p>
#           <div style="display: grid; grid-template-columns: 1fr; gap: 0.75rem;">
#             <.input
#               field={@form[:name]}
#               label="Name"
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
#             {if @action == :new, do: "Create Department", else: "Save Changes"}
#           </button>
#         </div>
#       </.form>
#     </div>
#     """
#   end

#   @impl true
#   def handle_event("validate", %{"department" => params}, socket) do
#     changeset =
#       socket.assigns.department
#       |> CxtDepartment.change_department(params)
#       |> Map.put(:action, :validate)

#     {:noreply, assign(socket, form: to_form(changeset))}
#   end

#   @impl true
#   def handle_event("save", %{"department" => params}, socket) do
#     case socket.assigns.action do
#       :new -> create_department(socket, params)
#       :edit -> update_department(socket, params)
#     end
#   end

#   defp create_department(socket, params) do
#     case CxtDepartment.create_department(params) do
#       {:ok, department} ->
#         notify_parent({:saved, department})

#         {:noreply,
#          socket
#          |> put_flash(:info, "Department created successfully")
#          |> push_patch(to: socket.assigns.patch)}

#       {:error, changeset} ->
#         {:noreply, assign(socket, form: to_form(changeset))}
#     end
#   end

#   defp update_department(socket, params) do
#     case CxtDepartment.update_department(socket.assigns.department, params) do
#       {:ok, department} ->
#         notify_parent({:saved, department})

#         {:noreply,
#          socket
#          |> put_flash(:info, "Department updated successfully")
#          |> push_patch(to: socket.assigns.patch)}

#       {:error, changeset} ->
#         {:noreply, assign(socket, form: to_form(changeset))}
#     end
#   end

#   defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
# end
