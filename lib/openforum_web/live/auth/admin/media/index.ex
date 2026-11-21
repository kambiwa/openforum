defmodule OpenforumWeb.Auth.Admin.Media.Index do
  use OpenforumWeb, :live_view

  alias Openforum.Context.{Documents, MediaResources}
  alias Openforum.Schema.MediaResource

  @impl true
  def mount(_params, _session, socket) do
    changeset = MediaResource.changeset(%MediaResource{}, %{})

    {:ok,
     socket
     |> assign(:page_title, "Media Library")
     |> assign(:current_page, :media)
     |> assign(:categories, Documents.list_categories_for_select())
     |> assign(:form, to_form(changeset))
     |> assign(:upload_error, nil)
     |> stream(
       :media_resources,
       MediaResources.list_for_uploader(socket.assigns.current_scope.user)
     )
     |> allow_upload(:media_file,
       accept: [
         ".mp4",
         ".webm",
         ".mov",
         ".mp3",
         ".wav",
         ".m4a",
         ".ogg",
         ".pdf",
         ".ppt",
         ".pptx",
         ".odp"
       ],
       max_entries: 1,
       max_file_size: 100_000_000
     )}
  end

  @impl true
  def handle_event("validate", %{"media_resource" => params}, socket) do
    changeset = MediaResource.changeset(%MediaResource{}, params) |> Map.put(:action, :validate)
    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :media_file, ref)}
  end

  def handle_event("save", %{"media_resource" => params}, socket) do
    case socket.assigns.uploads.media_file.entries do
      [] ->
        {:noreply, assign(socket, :upload_error, "Choose a file to upload.")}

      [_entry] ->
        uploaded =
          consume_uploaded_entries(socket, :media_file, fn %{path: temp_path}, entry ->
            filename = "#{Ecto.UUID.generate()}#{Path.extname(entry.client_name)}"
            upload_dir = Path.join([:code.priv_dir(:openforum), "static", "uploads", "media"])
            :ok = File.mkdir_p(upload_dir)
            :ok = File.cp(temp_path, Path.join(upload_dir, filename))
            {:ok, "/uploads/media/#{filename}"}
          end)

        case uploaded do
          [file_url] -> create_resource(socket, params, file_url)
          _ -> {:noreply, assign(socket, :upload_error, "The file could not be uploaded.")}
        end
    end
  end

  def handle_event("toggle_status", %{"id" => id}, socket) do
    user = socket.assigns.current_scope.user
    resource = MediaResources.get_for_uploader!(user, id)
    next_status = if resource.status == "published", do: "document", else: "published"

    case MediaResources.update_status(resource, next_status) do
      {:ok, updated} ->
        updated = %{updated | category: resource.category}

        {:noreply,
         socket
         |> stream_insert(:media_resources, updated)
         |> put_flash(:info, status_message(next_status))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not update this media item.")}
    end
  end

  def handle_event("delete", %{"id" => id}, socket) do
    resource = MediaResources.get_for_uploader!(socket.assigns.current_scope.user, id)

    case MediaResources.delete(resource) do
      {:ok, _deleted} ->
        delete_uploaded_file(resource.file_url)

        {:noreply,
         socket
         |> stream_delete(:media_resources, resource)
         |> put_flash(:info, "Media item deleted.")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not delete this media item.")}
    end
  end

  defp create_resource(socket, params, file_url) do
    attrs = Map.put(params, "file_url", file_url)

    case MediaResources.create(socket.assigns.current_scope.user, attrs) do
      {:ok, resource} ->
        resource = Openforum.Repo.preload(resource, :category)
        changeset = MediaResource.changeset(%MediaResource{}, %{})

        {:noreply,
         socket
         |> stream_insert(:media_resources, resource, at: 0)
         |> assign(:form, to_form(changeset))
         |> assign(:upload_error, nil)
         |> put_flash(:info, "Media uploaded.")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp status_message("published"), do: "Media published to the public library."
  defp status_message(_), do: "Media removed from the public library."

  defp delete_uploaded_file("/uploads/media/" <> filename) do
    path = Path.join([:code.priv_dir(:openforum), "static", "uploads", "media", filename])
    File.rm(path)
  end

  defp delete_uploaded_file(_), do: :ok

  defp media_type_label("video"), do: "Video"
  defp media_type_label("audio"), do: "Audio"
  defp media_type_label("presentation"), do: "Presentation"
  defp media_type_label(_), do: "Document"

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.admin_app flash={@flash} current_scope={@current_scope} current_page={@current_page}>
      <main class="mx-auto grid max-w-[1500px] gap-8 p-5 lg:grid-cols-[minmax(0,0.9fr)_minmax(0,1.1fr)] lg:p-8">
        <section class="h-fit border border-[#DDE4E8] bg-white">
          <div class="border-b border-[#DDE4E8] bg-[#0B2E4F] px-6 py-5">
            <p class="text-xs font-semibold uppercase tracking-[0.18em] text-[#D8B746]">
              Media studio
            </p>
            <h1 class="mt-2 text-2xl font-semibold tracking-tight text-white">Upload content</h1>
            <p class="mt-2 text-sm leading-6 text-white/70">
              Add a resource to your library, then publish it when it is ready for visitors.
            </p>
          </div>

          <.form
            for={@form}
            id="media-upload-form"
            phx-change="validate"
            phx-submit="save"
            class="space-y-5 p-6"
          >
            <.input field={@form[:title]} label="Title" placeholder="e.g. A teaching on grace" />
            <div class="grid gap-4 sm:grid-cols-2">
              <.input
                field={@form[:media_type]}
                type="select"
                label="Format"
                options={Enum.map(MediaResource.media_types(), &{media_type_label(&1), &1})}
              />
              <.input
                field={@form[:category_id]}
                type="select"
                label="Topic"
                options={@categories}
                prompt="Choose a topic"
              />
            </div>
            <.input
              field={@form[:duration_seconds]}
              type="number"
              label="Duration in seconds (optional)"
              min="0"
            />
            <.input
              field={@form[:description]}
              type="textarea"
              label="Description"
              rows="3"
              placeholder="What should visitors know about this resource?"
            />
            <.input
              field={@form[:status]}
              type="select"
              label="Visibility"
              options={[{"Keep as draft", "document"}, {"Publish now", "published"}]}
            />

            <div>
              <label for="media-file" class="mb-2 block text-sm font-medium text-[#0B2E4F]">Media file</label>
              <div
                class="border border-dashed border-[#9AB8CB] bg-[#F4F8FB] p-5"
                phx-drop-target={@uploads.media_file.ref}
              >
                <.live_file_input
                  upload={@uploads.media_file}
                  id="media-file"
                  class="block w-full text-sm text-[#526579] file:mr-4 file:border-0 file:bg-[#0B2E4F] file:px-4 file:py-2 file:font-medium file:text-white hover:file:bg-[#1769AA]"
                />
                <p class="mt-2 text-xs text-[#6B7280]">
                  Maximum file size: 100 MB. Accepted: MP4, WebM, MOV, MP3, WAV, M4A, OGG, PDF, PowerPoint and ODP.
                </p>
              </div>
              <div
                :for={entry <- @uploads.media_file.entries}
                class="mt-3 flex items-center justify-between border border-[#DDE4E8] px-3 py-2 text-sm"
              >
                <span class="truncate">{entry.client_name}</span>
                <button
                  type="button"
                  phx-click="cancel_upload"
                  phx-value-ref={entry.ref}
                  aria-label="Remove selected file"
                  class="ml-3 text-sm font-medium text-rose-700 hover:text-rose-900"
                >Remove</button>
              </div>
              <p :for={error <- upload_errors(@uploads.media_file)} class="mt-2 text-sm text-rose-700">
                {upload_error(error)}
              </p>
              <p :if={@upload_error} class="mt-2 text-sm text-rose-700">{@upload_error}</p>
            </div>

            <button
              id="media-upload-submit"
              type="submit"
              class="inline-flex min-h-11 items-center gap-2 bg-[#C9A227] px-5 text-sm font-semibold text-[#0B2E4F] transition-colors hover:bg-[#D8B746]"
            >
              <.icon name="hero-arrow-up-tray" class="size-4" /> Upload media
            </button>
          </.form>
        </section>

        <section>
          <div class="mb-5 flex items-end justify-between gap-4 border-b border-[#DDE4E8] pb-4">
            <div>
              <p class="text-xs font-semibold uppercase tracking-[0.18em] text-[#1769AA]">
                Your uploads
              </p>
              <h2 class="mt-2 text-2xl font-semibold tracking-tight text-[#0B2E4F]">Manage media</h2>
            </div>
            <.link
              navigate={~p"/media"}
              class="inline-flex items-center gap-2 text-sm font-semibold text-[#1769AA] hover:text-[#0B2E4F]"
            >
              View public library <.icon name="hero-arrow-up-right" class="size-4" />
            </.link>
          </div>

          <div id="media-resources" phx-update="stream" class="space-y-3">
            <div class="hidden only:block border border-dashed border-[#CBD5E1] bg-white px-6 py-12 text-center text-sm text-[#64748B]">
              Your uploaded media will appear here.
            </div>
            <article
              :for={{id, resource} <- @streams.media_resources}
              id={id}
              class="flex flex-col gap-4 border border-[#DDE4E8] bg-white p-5 sm:flex-row sm:items-center sm:justify-between"
            >
              <div class="min-w-0">
                <div class="flex flex-wrap items-center gap-2">
                  <span class="text-[11px] font-semibold uppercase tracking-[0.12em] text-[#A98618]">{media_type_label(
                    resource.media_type
                  )}</span>
                  <span class={[
                    "border px-2 py-0.5 text-[11px] font-semibold",
                    if(resource.status == "published",
                      do: "border-emerald-200 bg-emerald-50 text-emerald-700",
                      else: "border-amber-200 bg-amber-50 text-amber-800"
                    )
                  ]}>{if resource.status == "published", do: "Published", else: "Draft"}</span>
                </div>
                <h3 class="mt-2 truncate text-base font-semibold text-[#0B2E4F]">{resource.title}</h3>
                <p class="mt-1 truncate text-sm text-[#6B7280]">
                  {(resource.category && resource.category.name) || "Uncategorized"}{if resource.description,
                    do: " · " <> resource.description,
                    else: ""}
                </p>
              </div>
              <div class="flex shrink-0 items-center gap-3">
                <a
                  href={resource.file_url}
                  target="_blank"
                  rel="noopener noreferrer"
                  class="text-sm font-medium text-[#1769AA] hover:text-[#0B2E4F]"
                >Preview</a>
                <button
                  type="button"
                  phx-click="toggle_status"
                  phx-value-id={resource.id}
                  class="border border-[#4F7FA8]/40 px-3 py-2 text-sm font-medium text-[#0B2E4F] transition-colors hover:bg-[#EAF3F8]"
                >{if resource.status == "published", do: "Unpublish", else: "Publish"}</button>
                <button
                  type="button"
                  phx-click="delete"
                  phx-value-id={resource.id}
                  data-confirm={"Delete #{resource.title}?"}
                  class="px-2 py-2 text-sm font-medium text-rose-700 hover:text-rose-900"
                >Delete</button>
              </div>
            </article>
          </div>
        </section>
      </main>
    </Layouts.admin_app>
    """
  end

  defp upload_error(:too_large), do: "The selected file is larger than 100 MB."
  defp upload_error(:too_many_files), do: "Upload one file at a time."
  defp upload_error(_), do: "This file could not be accepted."
end
