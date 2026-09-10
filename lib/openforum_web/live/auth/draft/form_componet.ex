defmodule OpenforumWeb.Auth.Draft.FormComponent do
  use OpenforumWeb, :live_component

  alias Openforum.Context.Drafts

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
  def handle_event("validate", %{"content_item" => params}, socket) do
    IO.inspect(params, label: "=========Params in Draft FormComponent")
    changeset =
      socket.assigns.draft
      |> Drafts.change_draft(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"content_item" => params}, socket) do
    save_draft(socket, socket.assigns.draft.id, params)
  end

  def handle_event("show_submit_note", _params, socket) do
    {:noreply, assign(socket, :show_submit_note?, true)}
  end

  def handle_event("cancel_submit_note", _params, socket) do
    {:noreply, assign(socket, show_submit_note?: false, submit_note: "")}
  end

  def handle_event("update_submit_note", %{"note" => note}, socket) do
    {:noreply, assign(socket, :submit_note, note)}
  end

  def handle_event("submit_for_review", %{"content_item" => params}, socket) do
    case save_draft_silently(socket, socket.assigns.draft.id, params) do
      {:ok, draft} ->
        case Drafts.submit_draft(draft, socket.assigns.submit_note, socket.assigns.current_user) do
          {:ok, updated} ->
            notify_parent({:submitted, updated})
            {:noreply, socket}

          {:error, :no_reviewer_step} ->
            {:noreply, put_flash(socket, :error, "This workflow has no reviewer step configured.")}

          {:error, :note_required} ->
            {:noreply, put_flash(socket, :error, "Add a note for the reviewer before submitting.")}
        end

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("cancel", _params, socket) do
    notify_parent({:cancelled, socket.assigns.draft})
    {:noreply, socket}
  end

  defp save_draft(socket, nil, params) do
    case Drafts.create_draft(socket.assigns.current_user, params) do
      {:ok, draft} ->
        notify_parent({:saved, draft})
        {:noreply, put_flash(socket, :info, "Draft saved.")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_draft(socket, _id, params) do
    case Drafts.update_draft(socket.assigns.draft, params) do
      {:ok, draft} ->
        notify_parent({:saved, draft})
        {:noreply, put_flash(socket, :info, "Draft saved.")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  # Same as save_draft/3 but returns the tuple so submit_for_review can
  # chain straight into Drafts.submit_draft/3 without a flash in between.
  defp save_draft_silently(socket, nil, params), do: Drafts.create_draft(socket.assigns.current_user, params)
  defp save_draft_silently(socket, _id, params), do: Drafts.update_draft(socket.assigns.draft, params)

  defp assign_form(socket, changeset), do: assign(socket, :form, to_form(changeset))

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form for={@form} id="draft-form" phx-target={@myself} phx-change="validate" phx-submit="save">
        <div class="flex flex-col gap-4">
          <.input field={@form[:title]} type="text" label="Title" />
          <.input
            field={@form[:category_id]}
            type="select"
            label="Category"
            options={@categories}
            prompt="Choose a category"
          />
          <.input field={@form[:summary]} type="text" label="Summary" />

          <div class="flex flex-col gap-1.5">
            <label class="text-xs font-medium text-[#0B2E4F]">Body</label>
            <div
              id="draft-body-editor"
              phx-hook="RichTextEditor"
              phx-update="ignore"
              data-input-id="draft-body-input"
              data-initial-value={@form[:body].value}
            >
              <div id="draft-body-toolbar"></div>
              <div id="draft-body-container" class="min-h-[220px] rounded-lg border border-[#E5E7EB] bg-white p-3"></div>
            </div>
            <input type="hidden" name="content_item[body]" id="draft-body-input" value={@form[:body].value} />
          </div>

          <.input field={@form[:duration_label]} type="text" label="Duration label (optional)" />
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

          <button type="submit" class="rounded-lg bg-[#1769AA] px-4 py-2 text-sm font-medium text-white hover:bg-[#0B2E4F]">
            Save Draft
          </button>
        </div>

        <div :if={@show_submit_note?} class="mt-4 rounded-lg border border-[#E5E7EB] bg-[#F9FAFB] p-4">
          <label class="text-xs font-medium text-[#0B2E4F]">Note for reviewer (required)</label>
          <textarea
            name="note"
            rows="3"
            class="mt-1.5 w-full rounded-lg border border-[#E5E7EB] p-2 text-sm"
          >{@submit_note}</textarea>

          <div class="mt-3 flex justify-end gap-3">
            <button type="button" phx-click="cancel_submit_note" phx-target={@myself} class="text-sm text-[#6B7280]">
              Cancel
            </button>
            <button
              type="button"
              phx-click="submit_for_review"
              phx-target={@myself}
              class="rounded-lg bg-[#1E8E5A] px-4 py-2 text-sm font-medium text-white hover:bg-[#166B44]"
            >
              Confirm & Submit
            </button>
          </div>
        </div>
      </.form>
    </div>
    """
  end
end
