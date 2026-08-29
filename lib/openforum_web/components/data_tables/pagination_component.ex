defmodule OpenforumWeb.PaginationComponent do
  @moduledoc false
  use OpenforumWeb, :live_component
  import OpenforumWeb.SortTable.DataTable

  @distance 5

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign(pagination_assigns(assigns[:pagination_data]))

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="px-6 py-4 flex items-center justify-between">
      <div class="flex-1 flex justify-between sm:hidden">
        {prev_link_mobile(assigns, @params, @page_number)}
        {next_link_mobile(assigns, @params, @page_number, @total_pages)}
      </div>

      <div class="hidden sm:flex-1 sm:flex sm:items-center sm:justify-between">
        <div>
          <p class="text-sm text-gray-700">
            Showing
            <span class="font-medium">
              {if @total_entries != 0, do: (@page_number - 1) * @page_size + 1, else: 0}
            </span>
            -
            <span class="font-medium">
              {if @page_number * @page_size > @total_entries,
                do: @total_entries,
                else: @page_number * @page_size}
            </span>
            of <span class="font-medium">{@total_entries}</span>
            results
          </p>
        </div>

        <div>
          <nav
            class="relative z-0 inline-flex rounded-md shadow-sm -space-x-px"
            aria-label="Pagination"
          >
            {prev_link(assigns, @params, @page_number)}

            <%= for num <- start_page(@page_number)..end_page(@page_number, @total_pages) do %>
              <.link
                patch={"?" <> querystring(@params, page: num)}
                aria-current={if @page_number == num, do: "page"}
                class={[
                  "relative inline-flex items-center px-4 py-2 border text-sm font-medium",
                  if @page_number == num do
                    "z-10 bg-indigo-50 border-indigo-500 text-indigo-600"
                  else
                    "bg-white border-gray-300 text-gray-500 hover:bg-gray-50"
                  end
                ]}
              >
                {num}
              </.link>
            <% end %>

            {next_link(assigns, @params, @page_number, @total_pages)}
          </nav>
        </div>
      </div>
    </div>
    """
  end

  defp pagination_assigns(%{
         page_number: page_number,
         page_size: page_size,
         total_entries: total_entries,
         total_pages: total_pages
       }) do
    [
      page_number: page_number,
      page_size: page_size,
      total_entries: total_entries,
      total_pages: total_pages
    ]
  end

  defp pagination_assigns(_) do
    [
      page_number: 1,
      page_size: 10,
      total_entries: 0,
      total_pages: 0
    ]
  end

  defp prev_link_mobile(assigns, conn, current_page) do
    if current_page != 1 do
      patch = "?" <> querystring(conn, page: current_page - 1)
      assigns = assign(assigns, :patch, patch)

      ~H"""
      <.link
        patch={@patch}
        class="relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
      >
        Previous
      </.link>
      """
    else
      ~H"""
      <span class="relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-300 bg-white">
        Previous
      </span>
      """
    end
  end

  defp next_link_mobile(assigns, conn, current_page, num_pages) do
    if current_page != num_pages do
      patch = "?" <> querystring(conn, page: current_page - num_pages)
      assigns = assign(assigns, :patch, patch)

      ~H"""
      <.link
        patch={@patch}
        class="ml-3 relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
      >
        Next
      </.link>
      """
    else
      ~H"""
      <span class="ml-3 relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-300 bg-white">
        Next
      </span>
      """
    end
  end

  defp prev_link(assigns, conn, current_page) do
    if current_page != 1 do
      patch = "?" <> querystring(conn, page: current_page - 1)
      assigns = assign(assigns, patch: patch)

      ~H"""
      <.link
        patch={@patch}
        class="relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50"
      >
        <span class="sr-only">Previous</span>
        <i class="fas fa-chevron-left"></i>
      </.link>
      """
    else
      ~H"""
      <span class="relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-white text-sm font-medium text-gray-300">
        <span class="sr-only">Previous</span>
        <i class="fas fa-chevron-left"></i>
      </span>
      """
    end
  end

  defp next_link(assigns, conn, current_page, num_pages) do
    if current_page != num_pages do
      patch = "?" <> querystring(conn, page: current_page + 1)
      assigns = assign(assigns, patch: patch)

      ~H"""
      <.link
        patch={@patch}
        class="relative inline-flex items-center px-2 py-2 rounded-r-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50"
      >
        <span class="sr-only">Next</span>
        <i class="fas fa-chevron-right"></i>
      </.link>
      """
    else
      ~H"""
      <span class="relative inline-flex items-center px-2 py-2 rounded-r-md border border-gray-300 bg-white text-sm font-medium text-gray-300">
        <span class="sr-only">Next</span>
        <i class="fas fa-chevron-right"></i>
      </span>
      """
    end
  end

  def start_page(current_page) when current_page - @distance <= 0, do: 1
  def start_page(current_page), do: current_page - @distance

  def end_page(current_page, 0), do: current_page

  def end_page(current_page, total)
      when current_page <= @distance and @distance * 2 <= total do
    @distance * 2
  end

  def end_page(current_page, total) when current_page + @distance >= total, do: total
  def end_page(current_page, _total), do: current_page + @distance - 1
end
