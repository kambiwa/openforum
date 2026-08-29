defmodule OpenforumWeb.Datatable.Table do
  use Phoenix.Component

  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns = assign(assigns, :has_actions?, not Enum.empty?(assigns.action))

    ~H"""
    <div id={@id} class="overflow-hidden rounded-xl border border-[#E5E7EB] bg-white">
      <div class="overflow-x-auto">
        <table class="w-full border-collapse text-[0.83rem]">
          <%!-- ── Header ── --%>
          <thead>
            <tr class="bg-[#F4F8FB]">
              <th
                :for={col <- @col}
                class="whitespace-nowrap border-b border-[#E5E7EB] px-5 py-2.5 text-left text-[0.68rem] font-semibold uppercase tracking-[0.08em] text-[#6B7280]"
              >
                {col[:label]}
              </th>

              <th
                :if={@has_actions?}
                class="whitespace-nowrap border-b border-[#E5E7EB] px-5 py-2.5 text-left text-[0.68rem] font-semibold uppercase tracking-[0.08em] text-[#6B7280]"
              >
                Actions
              </th>
            </tr>
          </thead>

          <%!-- ── Body ── --%>
          <tbody>
            <tr :if={Enum.empty?(@rows)}>
              <td
                colspan={length(@col) + if(@has_actions?, do: 1, else: 0)}
                class="px-10 py-10 text-center text-sm text-[#6B7280]"
              >
                No records found
              </td>
            </tr>

            <tr
              :for={row <- @rows}
              id={@row_id && @row_id.(row)}
              class="border-t border-[#E5E7EB] transition-colors hover:bg-[#EAF3F8]/40"
            >
              <td
                :for={{col, _i} <- Enum.with_index(@col)}
                phx-click={@row_click && @row_click.(row)}
                class={["whitespace-nowrap px-5 py-3 text-[#252525]", @row_click && "cursor-pointer"]}
              >
                <div>{render_slot(col, @row_item.(row))}</div>
              </td>

              <td :if={@has_actions?} class="whitespace-nowrap px-5 py-3">
                <div class="flex items-center gap-2">
                  {render_slot(@action, row)}
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
    """
  end
end
