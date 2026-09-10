defmodule OpenforumWeb.Auth.Draft.FormComponent do
  use OpenforumWeb, :live_component

  alias Openforum.Context.Drafts

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> allow_upload(:attachment,
       accept: :any,
       max_entries: 1,
       max_file_size: 20_000_000
     )}
  end

  @impl true
  def update(%{draft: draft} = assigns, socket) do
    changeset = Drafts.change_draft(draft)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:categories, Drafts.list_categories_for_select())
     |> assign(:show_submit_note?, false)
     |> assign(:submit_note, "")
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"content_item" => params} = full, socket) do
    changeset = socket.assigns.draft |> Drafts.change_draft(params) |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(:submit_note, Map.get(full, "note", socket.assigns.submit_note))
     |> assign_form(changeset)}
  end

  def handle_event("save", %{"content_item" => params} = full, socket) do
    case Map.get(full, "form_action", "save") do
      "submit_for_review" -> do_submit_for_review(socket, params, full["note"])
      _ -> do_save(socket, params)
    end
  end

  def handle_event("show_submit_note", _params, socket) do
    {:noreply, assign(socket, :show_submit_note?, true)}
  end

  def handle_event("cancel_attachment_entry", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :attachment, ref)}
  end

  def handle_event("remove_attachment", %{"id" => id}, socket) do
    attachment = Drafts.get_attachment!(id)
    {:ok, _} = Drafts.delete_attachment(attachment)

    draft = Drafts.get_draft!(socket.assigns.current_user, socket.assigns.draft.id)
    {:noreply, assign(socket, :draft, draft)}
  end

  def handle_event("cancel", _params, socket) do
    notify_parent({:cancelled, socket.assigns.draft})
    {:noreply, socket}
  end

  defp do_save(socket, params) do
    case save_draft_silently(socket, socket.assigns.draft.id, params) do
      {:ok, draft} ->
        draft = persist_attachment(socket, draft)
        notify_parent({:saved, draft})
        {:noreply, put_flash(socket, :info, "Draft saved.")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp do_submit_for_review(socket, params, note) do
    case save_draft_silently(socket, socket.assigns.draft.id, params) do
      {:ok, draft} ->
        draft = persist_attachment(socket, draft)

        case Drafts.submit_draft(draft, note, socket.assigns.current_user) do
          {:ok, updated} ->
            notify_parent({:submitted, updated})
            {:noreply, socket}

          {:error, :no_reviewer_step} ->
            {:noreply, put_flash(socket, :error, "This workflow has no reviewer step configured.")}

          {:error, :note_required} ->
            {:noreply,
             socket |> assign(:show_submit_note?, true) |> put_flash(:error, "Add a note for the reviewer.")}
        end

      {:error, changeset} ->
        {:noreply, socket |> assign(:show_submit_note?, true) |> assign_form(changeset)}
    end
  end

  # Copies each uploaded entry into priv/static/uploads and records a
  # content_attachments row. Swap the destination for S3/Cloud storage
  # if that's where you're actually keeping files.
  defp persist_attachment(socket, draft) do
    consume_uploaded_entries(socket, :attachment, fn %{path: path}, entry ->
      filename = "#{Ecto.UUID.generate()}-#{entry.client_name}"
      dest = Path.join([:code.priv_dir(:openforum), "static", "uploads", filename])
      File.mkdir_p!(Path.dirname(dest))
      File.cp!(path, dest)

      {:ok, _} =
        Drafts.create_attachment(draft, %{
          "file_type" => entry.client_type,
          "file_url" => "/uploads/#{filename}",
          "caption" => entry.client_name
        })

      {:ok, dest}
    end)

    Drafts.get_draft!(socket.assigns.current_user, draft.id)
  end

  defp error_to_string(other), do: "Upload error: #{inspect(other)}"

  defp attachments(%{content_attachments: %Ecto.Association.NotLoaded{}}), do: []
  defp attachments(%{content_attachments: attachments}), do: attachments

  defp save_draft_silently(socket, nil, params), do: Drafts.create_draft(socket.assigns.current_user, params)
  defp save_draft_silently(socket, _id, params), do: Drafts.update_draft(socket.assigns.draft, params)

  defp assign_form(socket, changeset), do: assign(socket, :form, to_form(changeset))
  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp error_to_string(:too_large), do: "File is too large"
  defp error_to_string(:not_accepted), do: "Unacceptable file type"
  defp error_to_string(:too_many_files), do: "Only one attachment allowed"

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form for={@form} id="draft-form" phx-target={@myself} phx-change="validate" phx-submit="save">
        <div class="grid grid-cols-2 gap-4">
          <div class="flex flex-col gap-1.5">
            <label class="text-xs font-medium text-[#0B2E4F]">Title</label>
            <.input field={@form[:title]} type="text" placeholder="Enter Title" />
          </div>

          <div class="flex flex-col gap-1.5">
            <label class="text-xs font-medium text-[#0B2E4F]">Category</label>
            <.input
              field={@form[:category_id]}
              type="select"
              options={@categories}
              prompt="Choose a category"
            />
          </div>
        </div>

        <div class="mt-4 flex flex-col gap-1.5">
          <label class="text-xs font-medium text-[#0B2E4F]">Summary</label>
          <.input field={@form[:summary]} type="text" placeholder="Summary" />
        </div>

        <%!-- ATTACHMENT: drag & drop zone --%>
        <div class="mt-4 flex flex-col gap-1.5">
          <label class="text-xs font-medium text-[#0B2E4F]">Attachment</label>

          <div
            phx-drop-target={@uploads.attachment.ref}
            class="relative flex flex-col items-center justify-center gap-2 rounded-xl border-2 border-dashed border-[#B7CBE0] bg-[#EAF3F8] px-6 py-8 text-center"
          >
            <.live_file_input upload={@uploads.attachment} class="absolute inset-0 h-full w-full cursor-pointer opacity-0" />
            <.icon name="hero-arrow-down-tray" class="size-6 text-[#4F7FA8]" />
            <p class="text-xs text-[#4F7FA8]">Drag a file here, or click to browse</p>
          </div>

          <div :for={entry <- @uploads.attachment.entries} class="mt-2 flex items-center justify-between rounded-lg bg-[#F9FAFB] px-3 py-2 text-xs">
            <span class="text-[#252525]">{entry.client_name}</span>
            <button
              type="button"
              phx-click="cancel_attachment_entry"
              phx-value-ref={entry.ref}
              phx-target={@myself}
              class="rounded-full bg-red-50 px-1.5 py-1 text-red-600 hover:bg-red-100"
            >
              <.icon name="hero-x-mark" class="size-3" />
            </button>
          </div>
          <p :for={{_ref, msg} <- @uploads.attachment.errors} class="text-xs text-red-600">
            {error_to_string(msg)}
          </p>

          <div :for={attachment <- attachments(@draft)} class="mt-2 flex items-center justify-between rounded-lg border border-[#E5E7EB] px-3 py-2 text-xs">
            <a href={attachment.file_url} target="_blank" class="text-[#1769AA] hover:underline">
              {attachment.caption}
            </a>
            <button
              type="button"
              phx-click="remove_attachment"
              phx-value-id={attachment.id}
              phx-target={@myself}
              class="rounded-full bg-red-50 px-1.5 py-1 text-red-600 hover:bg-red-100"
            >
              <.icon name="hero-x-mark" class="size-3" />
            </button>
          </div>
        </div>

        <%!-- BODY: full rich text editor --%>
        <div class="mt-4 flex flex-col gap-1.5">
          <label class="text-xs font-medium text-[#0B2E4F]">Allegations / Description</label>

          <div id="draft-body-editor" phx-hook="RichTextEditor" phx-update="ignore" data-input-id="draft-body-input" data-initial-value={@form[:body].value}>
            <div data-editor-toolbar class="flex flex-wrap items-center gap-1 rounded-t-lg bg-[#1769AA] px-2 py-1.5"></div>
            <div data-editor-container class="min-h-[200px] rounded-b-lg border border-t-0 border-[#E5E7EB] bg-white p-3 text-sm"></div>
          </div>
          <input type="hidden" name="content_item[body]" id="draft-body-input" value={@form[:body].value} />
          <p :if={@form[:body].errors != []} class="text-xs text-red-600">
            <%= for {msg, _} <- @form[:body].errors do %>{msg}<% end %>
          </p>
        </div>

        <div class="mt-4 flex flex-col gap-1.5">
          <label class="text-xs font-medium text-[#0B2E4F]">Duration label (optional)</label>
          <.input field={@form[:duration_label]} type="text" placeholder="Duration label" />
        </div>

        <div class="mt-6 flex items-center justify-end gap-3">
          <button type="button" phx-click="cancel" phx-target={@myself} class="text-sm text-[#6B7280]">
            Cancel
          </button>

          <button
            :if={!@show_submit_note?}
            type="button"
            phx-click="show_submit_note"
            phx-target={@myself}
            class="rounded-lg border border-[#1769AA] px-4 py-2 text-sm font-medium text-[#1769AA] hover:bg-[#EAF3F8]"
          >
            Submit for Review
          </button>

          <button type="submit" name="form_action" value="save" class="rounded-lg bg-[#1769AA] px-4 py-2 text-sm font-medium text-white hover:bg-[#0B2E4F]">
            Save Draft
          </button>

          <button :if={@show_submit_note?} type="submit" name="form_action" value="submit_for_review" class="rounded-lg bg-[#1E8E5A] px-4 py-2 text-sm font-medium text-white hover:bg-[#166B44]">
            Confirm & Submit
          </button>
        </div>

        <div :if={@show_submit_note?} class="mt-4 rounded-lg border border-[#E5E7EB] bg-[#F9FAFB] p-4">
          <label class="text-xs font-medium text-[#0B2E4F]">Note for reviewer (required)</label>
          <textarea name="note" rows="3" class="mt-1.5 w-full rounded-lg border border-[#E5E7EB] p-2 text-sm">{@submit_note}</textarea>
        </div>
      </.form>
    </div>
    """
  end
end
