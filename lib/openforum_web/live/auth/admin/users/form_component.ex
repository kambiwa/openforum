# defmodule OpenforumWeb.User.FormComponent do
#   use OpenforumWeb, :live_component

#   alias EnrouteHaye.Context.CxtFood

#   @impl true
#   def update(%{user: user} = assigns, socket) do
#     changeset = CxtFood.change_user(user)

#     {:ok,
#      socket
#      |> assign(assigns)
#      |> allow_upload(:image,
#        accept: ~w(.jpg .jpeg .png .webp),
#        max_entries: 1,
#        max_file_size: 5_000_000
#      )
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
#             Fill in the details below to {if @action == :new, do: "create a new user item", else: "update the user item"}.
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
#         <%!-- ══ MAIN GRID: form left | upload right ══ --%>
#         <div style="display: grid; grid-template-columns: 1fr 180px; gap: 1rem; align-items: start; width: 100%; box-sizing: border-box;">

#           <%!-- LEFT COLUMN — form fields --%>
#           <div style="display: flex; flex-direction: column; gap: 1.25rem;">

#             <%!-- Section: User Info --%>
#             <div>
#               <p style="font-size: 0.7rem; font-weight: 700; color: #8B1A1A;
#                         text-transform: uppercase; letter-spacing: 0.1em; margin-bottom: 0.75rem;
#                         display: flex; align-items: center; gap: 0.4rem;">
#                 <span style="display: inline-block; width: 2rem; height: 1px; background: #8B1A1A;"></span>
#                 User Info
#               </p>
#               <div style="display: grid; grid-template-columns: 1fr; gap: 0.75rem;">
#                 <.input
#                   field={@form[:name]}
#                   label="Name"
#                 />
#                 <.input
#                   type="textarea"
#                   field={@form[:description]}
#                   label="Description"
#                   style="min-height: 80px; resize: vertical;"
#                 />
#               </div>
#             </div>

#             <%!-- Section: Pricing --%>
#             <div>
#               <p style="font-size: 0.7rem; font-weight: 700; color: #8B1A1A;
#                         text-transform: uppercase; letter-spacing: 0.1em; margin-bottom: 0.75rem;
#                         display: flex; align-items: center; gap: 0.4rem;">
#                 <span style="display: inline-block; width: 2rem; height: 1px; background: #8B1A1A;"></span>
#                 Pricing
#               </p>
#               <div style="display: grid; grid-template-columns: 1fr; gap: 0.75rem;">
#                 <.input
#                   field={@form[:price]}
#                   label="Price"
#                   type="number"
#                 />
#               </div>
#             </div>

#           </div>

#           <%!-- RIGHT COLUMN — image upload panel --%>
#           <div style="display: flex; flex-direction: column; gap: 0.75rem;">
#             <p style="font-size: 0.7rem; font-weight: 700; color: #8B1A1A;
#                       text-transform: uppercase; letter-spacing: 0.1em; margin-bottom: 0.1rem;
#                       display: flex; align-items: center; gap: 0.4rem;">
#               <span style="display: inline-block; width: 2rem; height: 1px; background: #8B1A1A;"></span>
#               Photo
#             </p>

#             <%!-- Drop zone --%>
#             <div
#               phx-drop-target={@uploads.image.ref}
#               style="border: 2px dashed #E8E2D9; border-radius: 0.65rem;
#                      background: #FAF8F5; padding: 1.25rem 0.75rem;
#                      display: flex; flex-direction: column; align-items: center;
#                      justify-content: center; gap: 0.5rem; text-align: center; min-height: 140px;
#                      width: 100%; box-sizing: border-box; transition: border-color 0.15s;"
#             >
#               <div style="width: 2.5rem; height: 2.5rem; background: rgba(139,26,26,0.08);
#                           border-radius: 50%; display: flex; align-items: center; justify-content: center;">
#                 <.icon name="hero-photo" style="width: 1.25rem; height: 1.25rem; color: #8B1A1A;" />
#               </div>
#               <div>
#                 <p style="font-size: 0.75rem; font-weight: 500; color: #374151; margin: 0;">
#                   Drop image here
#                 </p>
#                 <p style="font-size: 0.68rem; color: #9ca3af; margin: 0.1rem 0 0;">
#                   JPG, PNG, WEBP · max 5 MB
#                 </p>
#               </div>
#               <label style="margin-top: 0.25rem; padding: 0.35rem 0.9rem; font-size: 0.75rem;
#                             font-weight: 500; color: #8B1A1A; background: #fff;
#                             border: 1px solid #8B1A1A; border-radius: 0.4rem; cursor: pointer;">
#                 Browse
#                 <.live_file_input upload={@uploads.image} style="display: none;" />
#               </label>
#             </div>

#             <%!-- Entry preview --%>
#             <%= for entry <- @uploads.image.entries do %>
#               <div style="border: 1px solid #E8E2D9; border-radius: 0.5rem;
#                           padding: 0.5rem 0.65rem; background: #fff;
#                           display: flex; align-items: center; gap: 0.5rem;">
#                 <.live_img_preview entry={entry} style="width: 2.25rem; height: 2.25rem; object-fit: cover; border-radius: 0.3rem;" />
#                 <div style="flex: 1; min-width: 0;">
#                   <p style="font-size: 0.7rem; font-weight: 500; color: #374151;
#                             white-space: nowrap; overflow: hidden; text-overflow: ellipsis; margin: 0;">
#                     {entry.client_name}
#                   </p>
#                   <div style="margin-top: 0.2rem; height: 3px; background: #E8E2D9; border-radius: 99px; overflow: hidden;">
#                     <div style={"width: #{entry.progress}%; height: 100%; background: #8B1A1A; transition: width 0.3s;"}></div>
#                   </div>
#                 </div>
#                 <button
#                   type="button"
#                   phx-click="cancel-upload"
#                   phx-value-ref={entry.ref}
#                   phx-target={@myself}
#                   style="color: #9ca3af; background: none; border: none; cursor: pointer; padding: 0;"
#                 >
#                   <.icon name="hero-x-mark" style="width: 0.9rem; height: 0.9rem;" />
#                 </button>
#               </div>

#               <%= for err <- upload_errors(@uploads.image, entry) do %>
#                 <p style="font-size: 0.7rem; color: #dc2626; margin: 0;">{error_to_string(err)}</p>
#               <% end %>
#             <% end %>

#             <%= for err <- upload_errors(@uploads.image) do %>
#               <p style="font-size: 0.7rem; color: #dc2626; margin: 0;">{error_to_string(err)}</p>
#             <% end %>

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
#             {if @action == :new, do: "Create User", else: "Save Changes"}
#           </button>
#         </div>
#       </.form>
#     </div>
#     """
#   end

#   @impl true
#   def handle_event("cancel-upload", %{"ref" => ref}, socket) do
#     {:noreply, cancel_upload(socket, :image, ref)}
#   end

#   @impl true
#   def handle_event("validate", %{"user" => params}, socket) do
#     changeset =
#       socket.assigns.user
#       |> CxtFood.change_user(params)
#       |> Map.put(:action, :validate)

#     {:noreply, assign(socket, form: to_form(changeset))}
#   end

#   @impl true
#   def handle_event("save", %{"user" => params}, socket) do
#     image_url =
#       consume_uploaded_entries(socket, :image, fn %{path: path}, entry ->
#         dest = Path.join([:code.priv_dir(:enroute_haye), "static", "uploads", entry.client_name])
#         File.cp!(path, dest)
#         {:ok, "/uploads/#{entry.client_name}"}
#       end)
#       |> List.first()

#     params = if image_url, do: Map.put(params, "image_url", image_url), else: params

#     case socket.assigns.action do
#       :new -> create_user(socket, params)
#       :edit -> update_user(socket, params)
#     end
#   end

#   defp create_user(socket, params) do
#     case CxtFood.create_user(params) do
#       {:ok, user} ->
#         notify_parent({:saved, user})

#         {:noreply,
#          socket
#          |> put_flash(:info, "User created successfully")
#          |> push_patch(to: socket.assigns.patch)}

#       {:error, changeset} ->
#         {:noreply, assign(socket, form: to_form(changeset))}
#     end
#   end

#   defp update_user(socket, params) do
#     case CxtFood.update_user(socket.assigns.user, params) do
#       {:ok, user} ->
#         notify_parent({:saved, user})

#         {:noreply,
#          socket
#          |> put_flash(:info, "User updated successfully")
#          |> push_patch(to: socket.assigns.patch)}

#       {:error, changeset} ->
#         {:noreply, assign(socket, form: to_form(changeset))}
#     end
#   end

#   defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

#   defp error_to_string(:too_large), do: "File too large (max 5 MB)"
#   defp error_to_string(:not_accepted), do: "Unsupported file type"
#   defp error_to_string(:too_many_files), do: "Only 1 image allowed"
#   defp error_to_string(err), do: "Upload error: #{inspect(err)}"
# end
