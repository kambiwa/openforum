defmodule OpenforumWeb.Auth.Document.View do
  @moduledoc """
  Read-only view of a single document, rendered inside the modal in
  `OpenforumWeb.Auth.Document.Index` when `live_action == :view`.

  The document is shown as a letter on a page: logo letterhead top right,
  large title, justified body, and a small footer (title, date, language).
  Above the page sits a status banner that tells the current user what
  action (if any) is pending on this document.

  Required assigns: `:document` and `:current_user`.

  Events ("edit", "close") have no `phx-target`, so they go to the parent
  LiveView, which already handles both.
  """
  use OpenforumWeb, :live_component

  @logo_alt "New Apostolic Church Zambia"

  @impl true
  def render(assigns) do
    assigns =
      assigns
      |> assign(:logo_alt, @logo_alt)
      |> assign(:pending, pending_action(assigns.document, assigns[:current_user]))

    ~H"""
    <div id={"document-view-#{@document.id}"} class="flex flex-col gap-4">
      <%!-- Status banner: current state + what the current user needs to do --%>
      <div class={["flex items-start gap-3 rounded-lg border px-4 py-3", banner_class(@pending.tone)]}>
        <.icon name={banner_icon(@pending.tone)} class="mt-0.5 size-5 shrink-0" />
        <div class="min-w-0 flex-1">
          <div class="flex flex-wrap items-center gap-2">
            <span class="text-[0.82rem] font-semibold">{status_label(@document.status)}</span>
            <span class={[
              "rounded-full px-2 py-0.5 text-[0.65rem] font-medium uppercase tracking-wide",
              @pending.badge_class
            ]}>
              {@pending.badge}
            </span>
          </div>
          <p class="mt-0.5 text-[0.78rem]">{@pending.message}</p>
        </div>
      </div>

      <%!-- Meta line --%>
      <div class="flex flex-wrap items-center gap-x-5 gap-y-1 text-xs text-[#6B7280]">
        <span>
          <span class="font-medium text-[#0B2E4F]">Category:</span> {category_name(@document)}
        </span>
        <span>
          <span class="font-medium text-[#0B2E4F]">Author:</span> {author_name(@document)}
        </span>
        <span :if={@document.duration_label}>
          <span class="font-medium text-[#0B2E4F]">Reading time:</span> {@document.duration_label}
        </span>
      </div>

      <%!-- The page --%>
      <div class="max-h-[60vh] overflow-y-auto rounded-lg border border-[#E5E7EB] bg-[#F3F4F6] p-4">
        <article class="mx-auto flex min-h-[40rem] max-w-[40rem] flex-col bg-white px-10 py-8 shadow-sm">
          <%!-- Letterhead --%>
          <header class="flex justify-end border-b border-[#E5E7EB] pb-4">
            <img
              src={~p"/images/nac/logo.jpg"}
              alt={@logo_alt}
              class="h-14 w-auto object-contain"
            />
          </header>
           <%!-- <p class="text-lg font-bold color-[#0B2E4F]">New Apostolic Church Zambia</p> --%>
          <%!-- Title --%>
          <h2 class="mt-10 text-[1.5rem] font-medium text-[#252525]">{@document.title}</h2>

          <p :if={@document.summary} class="mt-2 text-[0.8rem] italic text-[#6B7280]">
            {@document.summary}
          </p>

          <%!-- Body --%>
          <div class={[
            "mt-8 flex-1 break-words text-justify text-[0.8rem] leading-relaxed text-[#252525]",
            "[&_p]:mb-4 [&_strong]:font-bold [&_b]:font-bold [&_em]:italic",
            "[&_h1]:mb-2 [&_h1]:text-base [&_h1]:font-bold [&_h2]:mb-2 [&_h2]:font-semibold",
            "[&_ul]:mb-4 [&_ul]:list-disc [&_ul]:pl-6 [&_ol]:mb-4 [&_ol]:list-decimal [&_ol]:pl-6",
            "[&_pre]:mb-4 [&_pre]:overflow-x-auto [&_pre]:whitespace-pre [&_pre]:rounded [&_pre]:bg-[#F3F4F6] [&_pre]:p-3 [&_pre]:text-xs",
            "[&_img]:inline-block [&_img]:max-h-24 [&_a]:text-[#1769AA] [&_a]:underline"
          ]}>
            {safe_body(@document.body)}
          </div>

          <%!-- Footer: title, date, language --%>
          <footer class="mt-10 border-t border-[#E5E7EB] pt-3 text-[0.6rem] leading-snug text-[#6B7280]">
            <p class="font-semibold text-[#252525]">{@document.title}</p>
            <p>{format_date(@document.updated_at)}</p>
            <p>{language_label(@document)}</p>
          </footer>
        </article>
      </div>

      <div class="flex items-center justify-end gap-3 border-t border-[#E5E7EB] pt-4">
        <button
          type="button"
          phx-click="close"
          class="rounded-lg border border-[#E5E7EB] bg-white px-4 py-2 text-[0.82rem] font-medium text-[#0B2E4F] hover:bg-[#EAF3F8]"
        >
          Close
        </button>

        <button
          :if={editable?(@document)}
          type="button"
          phx-click="edit"
          phx-value-id={@document.id}
          class="inline-flex items-center gap-1.5 rounded-lg bg-[#1769AA] px-4 py-2 text-[0.82rem] font-medium text-white hover:bg-[#0B2E4F]"
        >
          <.icon name="hero-pencil-square" class="size-4" /> Edit
        </button>
      </div>
    </div>
    """
  end

  # ── Pending action ──────────────────────────────────────────────────
  #
  # Returns %{tone, badge, badge_class, message} describing what the
  # *current user* needs to do. Adjust `reviewer?/1` to your real roles.

  defp pending_action(%{status: "document"} = doc, user) do
    if author?(doc, user) do
      action("Action required", :action, "Finish your draft and submit it for review.")
    else
      action("No action", :neutral, "This document is still a draft with its author.")
    end
  end

  defp pending_action(%{status: "in_review"} = doc, user) do
    cond do
      reviewer?(user) and not author?(doc, user) ->
        action(
          "Action required",
          :action,
          "Pending your action: review this document, then approve or reject it."
        )

      author?(doc, user) ->
        action(
          "Waiting",
          :waiting,
          "Submitted for review. Pending action from a reviewer — nothing needed from you."
        )

      true ->
        action("Waiting", :waiting, "Pending action from a reviewer.")
    end
  end

  defp pending_action(%{status: "rejected"} = doc, user) do
    if author?(doc, user) do
      action(
        "Action required",
        :rejected,
        "Pending your action: revise the document and resubmit it for review."
      )
    else
      action("No action", :neutral, "Rejected — waiting for the author to revise.")
    end
  end

  defp pending_action(%{status: "published"}, _user),
    do: action("Done", :done, "Published. No pending action.")

  defp pending_action(_doc, _user), do: action("No action", :neutral, "No pending action.")

  defp action(badge, tone, message) do
    %{tone: tone, badge: badge, badge_class: badge_class(tone), message: message}
  end

  defp author?(%{author_id: author_id}, %{id: user_id}) when not is_nil(author_id),
    do: author_id == user_id

  defp author?(_doc, _user), do: false

  # TODO: replace with your real role / permission check.
  defp reviewer?(%{role: role}) when role in ~w(reviewer editor admin), do: true
  defp reviewer?(_user), do: false

  defp banner_class(:action), do: "border-amber-200 bg-amber-50 text-amber-800"
  defp banner_class(:waiting), do: "border-blue-200 bg-[#EAF3F8] text-[#1769AA]"
  defp banner_class(:rejected), do: "border-red-200 bg-red-50 text-red-700"
  defp banner_class(:done), do: "border-green-200 bg-green-50 text-green-700"
  defp banner_class(_), do: "border-[#E5E7EB] bg-white text-[#6B7280]"

  defp banner_icon(:action), do: "hero-exclamation-circle"
  defp banner_icon(:waiting), do: "hero-clock"
  defp banner_icon(:rejected), do: "hero-x-circle"
  defp banner_icon(:done), do: "hero-check-circle"
  defp banner_icon(_), do: "hero-information-circle"

  defp badge_class(:action), do: "bg-amber-100 text-amber-800"
  defp badge_class(:waiting), do: "bg-blue-100 text-[#1769AA]"
  defp badge_class(:rejected), do: "bg-red-100 text-red-700"
  defp badge_class(:done), do: "bg-green-100 text-green-700"
  defp badge_class(_), do: "bg-gray-100 text-[#6B7280]"

  # ── Helpers ─────────────────────────────────────────────────────────

  # Only documents still at the Document stage are editable by the author.
  defp editable?(%{status: "document"}), do: true
  defp editable?(_), do: false

  defp category_name(%{category: %{name: name}}), do: name
  defp category_name(_), do: "—"

  # Requires `:author` to be preloaded in Documents.get_document!/2.
  defp author_name(%{author: %{first_name: f, last_name: l}}), do: "#{f} #{l}"
  defp author_name(_), do: "—"

  # "6 October 2019"
  defp format_date(nil), do: ""
  defp format_date(dt), do: "#{dt.day} #{Calendar.strftime(dt, "%B %Y")}"

  # Uses a :language field if the schema has one, otherwise defaults to English.
  defp language_label(doc) do
    case Map.get(doc, :language) do
      lang when is_binary(lang) and lang != "" -> lang
      _ -> "English"
    end
  end

  # "in_review" -> "In review"
  defp status_label(nil), do: "Unknown"

  defp status_label(status),
    do: status |> to_string() |> String.replace("_", " ") |> String.capitalize()

  # NOTE: `raw/1` renders the stored HTML as-is. That's only safe if the body
  # is sanitised on save (e.g. with HtmlSanitizeEx) or all authors are trusted.
  # If you add HtmlSanitizeEx, change this to:
  #   body |> HtmlSanitizeEx.basic_html() |> raw()
  defp safe_body(nil), do: ""
  defp safe_body(body), do: raw(body)
end
