# defmodule OpenforumWeb.Auth.Admin.JobType do
#   use OpenforumWeb, :live_view

#   alias OpenforumWeb.PaginationComponent
#   alias OpenforumWeb.Datatable.Table
#   alias OpenforumWeb.Pagination
#   alias OpenforumWeb.Context.CxtJobType
#   alias EnrouteHaye.Schema.JobType
#   alias OpenforumWeb.Repo

#   @impl true
#   def mount(_params, _session, socket) do
#     socket =
#       socket
#       |> assign(:page_title, "Job Types")
#       |> assign(:data_loader, false)
#       |> assign(:data, [])
#       |> assign(:data_pagenations, [])
#       |> assign(filter_expanded: false)
#       |> assign(:status_filter, "")
#       |> assign(:search_filter, "")
#       |> assign(:job_type, %JobType{})
#       |> Pagination.order_by_composer()
#       |> Pagination.i_search_composer()

#     {:ok, socket}
#   end

#   @impl true
#   def handle_params(params, _url, socket) do
#     {:noreply,
#      socket
#      |> assign(params: %{})
#      |> apply_action(socket.assigns.live_action, params)}
#   end

#   defp apply_action(socket, :edit, %{"id" => id}) do
#     socket
#     |> assign(:page_title, "Edit Job Type")
#     |> assign(:job_type, CxtJobType.get_job_type!(id))
#   end

#   defp apply_action(socket, :new, _params) do
#     socket
#     |> assign(:page_title, "New Job Type")
#     |> assign(:job_type, %JobType{})
#   end

#   defp apply_action(socket, :index, _params) do
#     socket
#     |> assign(:page_title, "Jobs Type")
#     |> assign(:job_type, nil)
#     |> fetch_filtered_job_type()
#   end

#   @impl true
#   def handle_info(
#         {OpenforumWeb.JobTypes.FormComponent, {:saved, _job_type}},
#         socket
#       ) do
#     {:noreply, fetch_filtered_job_type(socket)}
#   end

#   @impl true
#   def handle_event("add_job_type", _params, socket) do
#     {:noreply,
#      socket
#      |> assign(:page_title, "New Job Type")
#      |> assign(:job_type, %JobType{})
#      |> assign(:live_action, :new)}
#   end

#   def handle_event("edit", %{"id" => id}, socket) do
#     {:noreply,
#      socket
#      |> assign(:page_title, "Edit Job Type")
#      |> assign(:job_type, CxtJobType.get_job_type!(id))
#      |> assign(:live_action, :edit)}
#   end

#   @impl true
#   def handle_event("close", _params, socket) do
#     {:noreply, assign(socket, :live_action, :index)}
#   end

#   @impl true
#   def handle_event("toggle-filter", _, socket) do
#     {:noreply, assign(socket, filter_expanded: !socket.assigns.filter_expanded)}
#   end

#   @impl true
#   def handle_event("filter", %{"filter" => filters} = _params, socket) do
#     {:noreply,
#      socket
#      |> assign(:status_filter, filters["status_filter"])
#      |> assign(:search_filter, filters["search_filter"])
#      |> fetch_filtered_job_type()}
#   end

#   defp fetch_filtered_job_type(socket) do
#     filters = %{
#       search_filter: socket.assigns.search_filter,
#       status_filter: socket.assigns.status_filter
#     }

#     data =
#       CxtJobType.list_job_types(
#         Pagination.create_table_params(socket, socket.assigns.params),
#         filters
#       )

#     socket
#     |> assign(:data, data.entries)
#     |> assign(:data_pagenations, Map.drop(data, [:entries]))
#     |> assign(data_loader: false)
#   end

#   # ── Render ───────────────────────────────────────────────────────────

#   @impl true
#   def render(assigns) do
#     ~H"""
#     <Layouts.admin_app flash={@flash} current_scope={@current_scope} current_page={:job_type}>
#       <div style="padding: 1.5rem; display: flex; flex-direction: column; gap: 1.5rem;">

#         <%!-- ══ PAGE HEADER ══ --%>
#         <div style="display: flex; align-items: center; justify-content: space-between;">
#           <div>
#             <h1 style="font-size: 1.1rem; font-weight: 700; color: #1a1a1a; margin-bottom: 0.2rem;">
#               Job Type Management
#             </h1>
#             <p style="font-size: 0.82rem; color: #9ca3af;">
#               Manage job type listings and their details.
#             </p>
#           </div>

#           <div style="display: flex; align-items: center; gap: 0.75rem;">
#             <%!-- Filter toggle --%>
#             <button
#               phx-click="toggle-filter"
#               style="display: inline-flex; align-items: center; gap: 0.4rem;
#                      padding: 0.45rem 1rem; font-size: 0.82rem; font-weight: 500;
#                      color: #374151; background: #fff; border: 1px solid #E8E2D9;
#                      border-radius: 0.5rem; cursor: pointer; transition: background 0.15s;"
#               onmouseover="this.style.background='#FAF8F5'"
#               onmouseout="this.style.background='#fff'"
#             >
#               <.icon name="hero-funnel" class="size-4" /> Filter
#             </button>

#             <%!-- New job_type --%>
#             <button
#               phx-click="add_job_type"
#               style="display: inline-flex; align-items: center; gap: 0.4rem;
#                      padding: 0.45rem 1rem; font-size: 0.82rem; font-weight: 500;
#                      color: #fff; background: #8B1A1A; border: none;
#                      border-radius: 0.5rem; cursor: pointer; transition: opacity 0.15s;"
#               onmouseover="this.style.opacity='0.88'"
#               onmouseout="this.style.opacity='1'"
#             >
#               <.icon name="hero-plus" class="size-4" /> New Job type
#             </button>
#           </div>
#         </div>

#         <%!-- ══ FILTER PANEL ══ --%>
#         <%= if @filter_expanded do %>
#           <div style="background: #fff; border: 1px solid #E8E2D9;
#                       border-top: 3px solid #8B1A1A; border-radius: 0.75rem; padding: 1.25rem;">
#             <p style="font-size: 0.75rem; font-weight: 600; color: #374151;
#                       text-transform: uppercase; letter-spacing: 0.08em; margin-bottom: 1rem;">
#               Filters
#             </p>
#             <.form for={%{}} as={:filter} phx-change="filter">
#               <div style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 1rem;">

#                 <div style="display: flex; flex-direction: column; gap: 0.35rem;">
#                   <label style="font-size: 0.75rem; font-weight: 500; color: #374151;">Search</label>
#                   <.input
#                     name="filter[search_filter]"
#                     placeholder="Search job_type..."
#                     value={@search_filter}
#                   />
#                 </div>

#                 <div style="display: flex; flex-direction: column; gap: 0.35rem;">
#                   <label style="font-size: 0.75rem; font-weight: 500; color: #374151;">Status</label>
#                   <.input
#                     type="select"
#                     name="filter[status_filter]"
#                     prompt="All"
#                     options={[{"Active", "active"}, {"Inactive", "inactive"}]}
#                     value={@status_filter}
#                   />
#                 </div>

#               </div>
#             </.form>
#           </div>
#         <% end %>

#         <%!-- ══ TABLE CARD ══ --%>
#         <div style="background: #fff; border: 1px solid #E8E2D9; border-radius: 0.75rem; overflow: hidden;">

#           <div style="padding: 1rem 1.25rem; border-bottom: 1px solid #E8E2D9;">
#             <h2 style="font-size: 0.85rem; font-weight: 600; color: #374151;">All Jobs</h2>
#           </div>

#           <Table.table id="tbl_job" rows={@data}>
#             <:col :let={job_type} label="Name">
#               <span style="color: #374151; font-weight: 500;">{job_type.name}</span>
#             </:col>
#             <:col :let={job_type} label="Status">
#               <span style="color: #6b7280;">{job_type.status}</span>
#             </:col>

#             <:action :let={job_type}>
#               <button
#                 phx-click="edit"
#                 phx-value-id={job_type.id}
#                 style="display: inline-flex; align-items: center; gap: 0.3rem;
#                        padding: 0.25rem 0.65rem; font-size: 0.75rem; font-weight: 500;
#                        color: #8B1A1A; background: rgba(139,26,26,0.08);
#                        border: none; border-radius: 0.4rem; cursor: pointer; transition: background 0.15s;"
#                 onmouseover="this.style.background='rgba(139,26,26,0.15)'"
#                 onmouseout="this.style.background='rgba(139,26,26,0.08)'"
#               >
#                 <.icon name="hero-pencil-square" class="size-3" /> Edit
#               </button>
#             </:action>
#           </Table.table>

#           <%!-- Loading spinner --%>
#           <%= if @data_loader do %>
#             <div style="padding: 2.5rem; text-align: center;">
#               <svg xmlns="http://www.w3.org/2000/svg"
#                    style="width: 2rem; height: 2rem; color: #8B1A1A; animation: spin 1s linear infinite; margin: 0 auto;"
#                    fill="none" viewBox="0 0 24 24">
#                 <circle style="opacity: 0.25;" cx="12" cy="12" r="10"
#                         stroke="currentColor" stroke-width="4"/>
#                 <path style="opacity: 0.75;" fill="currentColor"
#                       d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962
#                          7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"/>
#               </svg>
#             </div>
#           <% end %>

#           <%!-- Pagination --%>
#           <div style="border-top: 1px solid #E8E2D9;">
#             <.live_component
#               module={OpenforumWeb.PaginationComponent}
#               id="PaginationComponent"
#               params={@params}
#               pagination_data={@data_pagenations}
#             />
#           </div>

#         </div>

#         <%!-- ══ MODAL ══ --%>
#         <%= if @live_action in [:new, :edit] do %>
#           <.modal
#             id={"crud-job_type-modal-#{(@job_type && @job_type.id) || :new}"}
#             show
#             on_cancel={JS.push("close")}
#           >
#             <.live_component
#               module={OpenforumWeb.JobType.FormComponent}
#               id={(@job_type && @job_type.id) || :new}
#               title={@page_title}
#               action={@live_action}
#               job_type={@job_type}
#               patch={~p"/admin/job_type"}
#             />
#           </.modal>
#         <% end %>

#       </div>
#     </Layouts.admin_app>
#     """
#   end
# end
