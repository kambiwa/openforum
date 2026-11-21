defmodule OpenforumWeb.Datatable.Table do
  use Phoenix.Component
  import OpenforumWeb.CoreComponents, only: [icon: 1]

  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"
  attr :loading, :boolean, default: false
  attr :empty_message, :string, default: "No records found"
  attr :loading_message, :string, default: "Loading records…"
  attr :actions_label, :string, default: "Actions"
  attr :options_label, :string, default: "Options"
  attr :actions_mode, :string, default: "dropdown"
  attr :striped, :boolean, default: false
  attr :compact, :boolean, default: false

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
    attr :icon, :string, doc: "optional explicit heroicon name for the column heading"
    attr :status_field, :atom, doc: "render this field as a styled status badge"
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns = assign(assigns, :has_actions?, not Enum.empty?(assigns.action))

    ~H"""
    <div
      id={@id}
      class="overflow-hidden rounded-xl border border-[#E5E7EB] bg-white shadow-sm"
      aria-busy={to_string(@loading)}
    >
      <div class="overflow-x-auto">
        <table class="w-full border-collapse text-[0.83rem]">
          <thead>
            <tr class="bg-[#0B2E4F]">
              <th
                :for={col <- @col}
                scope="col"
                class="whitespace-nowrap border-b border-[#1769AA] px-5 py-3 text-left text-[0.68rem] font-semibold uppercase tracking-[0.1em] text-white/85"
              >
                <span class="inline-flex items-center gap-2">
                  <.icon name={col[:icon] || column_icon(col[:label])} class="size-4 text-[#D8B746]" />
                  {col[:label]}
                </span>
              </th>

              <th
                :if={@has_actions?}
                scope="col"
                class="whitespace-nowrap border-b border-[#1769AA] px-5 py-3 text-left text-[0.68rem] font-semibold uppercase tracking-[0.1em] text-white/85"
              >
                <span class="inline-flex items-center gap-2">
                  <.icon name="hero-ellipsis-horizontal" class="size-4 text-[#D8B746]" />
                  {@actions_label}
                </span>
              </th>
            </tr>
          </thead>

          <tbody class="divide-y divide-[#EEF1F4]">
            <tr :if={@loading}>
              <td
                colspan={length(@col) + if(@has_actions?, do: 1, else: 0)}
                class="px-6 py-12 text-center"
              >
                <div role="status" class="inline-flex items-center gap-3 text-sm text-[#6B7280]">
                  <span class="size-5 animate-spin rounded-full border-2 border-[#CDE1EF] border-t-[#1769AA]" />
                  {@loading_message}
                </div>
              </td>
            </tr>

            <tr :if={!@loading and Enum.empty?(@rows)}>
              <td
                colspan={length(@col) + if(@has_actions?, do: 1, else: 0)}
                class="px-10 py-12 text-center"
              >
                <div class="mx-auto flex max-w-sm flex-col items-center gap-2">
                  <span class="flex size-10 items-center justify-center rounded-full bg-[#F4F8FB] text-[#8A9AAA]">
                    <.icon name="hero-inbox" class="size-5" />
                  </span>
                  <span class="text-sm font-medium text-[#34495E]">{@empty_message}</span>
                </div>
              </td>
            </tr>

            <tr
              :for={{row, index} <- Enum.with_index(@rows)}
              :if={!@loading}
              id={@row_id && @row_id.(row)}
              class={[
                "transition-colors hover:bg-[#EAF3F8]/60",
                @striped && rem(index, 2) == 1 && "bg-[#FAFBFC]"
              ]}
            >
              <td
                :for={col <- @col}
                phx-click={@row_click && @row_click.(row)}
                class={[
                  "text-[#252525]",
                  if(@compact, do: "px-4 py-2", else: "px-5 py-3"),
                  @row_click && "cursor-pointer"
                ]}
              >
                <%= if col[:status_field] do %>
                  <.status_badge value={Map.get(@row_item.(row), col[:status_field])} />
                <% else %>
                  <div>{render_slot(col, @row_item.(row))}</div>
                <% end %>
              </td>

              <td :if={@has_actions?} class={if(@compact, do: "px-4 py-2", else: "px-5 py-3")}>
                <%= if @actions_mode == "inline" do %>
                  <div class="flex items-center gap-2">
                    {render_slot(@action, row)}
                  </div>
                <% else %>
                  <details class="group relative inline-block text-left">
                    <summary class="inline-flex cursor-pointer list-none items-center gap-1.5 rounded-lg border border-[#D9E2EA] bg-white px-3 py-1.5 text-xs font-semibold text-[#34495E] shadow-sm transition hover:border-[#AFC6D8] hover:bg-[#F4F8FB] focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#1769AA] [&::-webkit-details-marker]:hidden">
                      <.icon name="hero-ellipsis-horizontal" class="size-4" />
                      <span>{@options_label}</span>
                      <.icon
                        name="hero-chevron-down"
                        class="size-3 transition-transform group-open:rotate-180"
                      />
                    </summary>

                    <div class="pointer-events-none invisible absolute left-full top-1/2 z-50 ml-2 min-w-44 -translate-y-1/2 translate-x-1 rounded-xl border border-[#E5E7EB] bg-white p-1.5 opacity-0 shadow-xl shadow-[#0B2E4F]/10 transition duration-150 ease-out group-open:pointer-events-auto group-open:visible group-open:translate-x-0 group-open:opacity-100">
                      <div class="flex flex-col gap-1">
                        {render_slot(@action, row)}
                      </div>
                    </div>
                  </details>
                <% end %>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
    """
  end

  defp column_icon(nil), do: "hero-table-cells"

  defp column_icon(label) do
    label = String.downcase(label)

    cond do
      String.contains?(label, ["title", "name", "profile"]) ->
        "hero-identification"

      String.contains?(label, ["category", "topic"]) ->
        "hero-folder"

      String.contains?(label, ["email"]) ->
        "hero-envelope"

      String.contains?(label, ["role", "permission"]) ->
        "hero-shield-check"

      String.contains?(label, ["status"]) ->
        "hero-check-circle"

      String.contains?(label, ["date", "updated", "published", "submitted"]) ->
        "hero-calendar-days"

      String.contains?(label, ["step"]) ->
        "hero-arrows-right-left"

      String.contains?(label, ["description", "summary"]) ->
        "hero-bars-3-bottom-left"

      String.contains?(label, ["author", "user"]) ->
        "hero-user"

      String.contains?(label, ["count", "total", "steps"]) ->
        "hero-hashtag"

      true ->
        "hero-table-cells"
    end
  end

  defp status_badge(assigns) do
    value = if is_nil(assigns.value), do: "unknown", else: to_string(assigns.value)
    normalized = String.downcase(value)

    assigns =
      assigns
      |> assign(:label, value |> String.replace("_", " ") |> String.capitalize())
      |> assign(:status_class, status_class(normalized))

    ~H"""
    <span class={[
      "inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-xs font-semibold",
      @status_class
    ]}>
      <span class="size-1.5 rounded-full bg-current opacity-70" />
      {@label}
    </span>
    """
  end

  defp status_class(status)
       when status in ["active", "published", "approved", "completed", "success"] do
    "bg-emerald-50 text-emerald-700 ring-1 ring-inset ring-emerald-200"
  end

  defp status_class(status)
       when status in ["pending", "pending_review", "document", "draft", "scheduled", "in_review"] do
    "bg-amber-50 text-amber-700 ring-1 ring-inset ring-amber-200"
  end

  defp status_class(status) when status in ["rejected", "failed", "error", "suspended"] do
    "bg-rose-50 text-rose-700 ring-1 ring-inset ring-rose-200"
  end

  defp status_class(status) when status in ["inactive", "disabled", "archived", "unknown"] do
    "bg-slate-100 text-slate-600 ring-1 ring-inset ring-slate-200"
  end

  defp status_class(_), do: "bg-sky-50 text-sky-700 ring-1 ring-inset ring-sky-200"
end
