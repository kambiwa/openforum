defmodule OpenforumWeb.SortTable.DataTable do
  @moduledoc """
  Utilities for sortable data tables with pagination support.

  Provides functions to:
  - Parse sort parameters from URLs
  - Generate sortable table header links
  - Build querystrings while preserving filters
  """

  use Phoenix.Component

  @default_direction "asc"
  @default_field :id
  @valid_directions ~w(asc desc)

  def sort(%{"sort_field" => field, "sort_direction" => direction})
      when direction in @valid_directions do
    {String.to_atom(direction), String.to_existing_atom(field)}
  rescue
    ArgumentError ->
      # Field doesn't exist as atom, return default
      {String.to_atom(@default_direction), @default_field}
  end

  def sort(_other) do
    {String.to_atom(@default_direction), @default_field}
  end

  @doc """
  Generates a sortable table header link component.

  ## Attributes
  - params: Current URL parameters
  - text: Link text (column header)
  - field: Database field to sort by
  - class: Additional CSS classes (optional)
  - show_icon: Whether to show sort icon (optional, default: true)
  """
  attr :params, :map, required: true
  attr :text, :string, required: true
  attr :field, :atom, required: true

  attr :class, :string,
    default: "flex items-center gap-2 hover:text-blue-600 transition-colors cursor-pointer"

  attr :show_icon, :boolean, default: true

  def table_link(assigns) do
    current_field = assigns.params["sort_field"]
    current_direction = assigns.params["sort_direction"]

    is_active = current_field == to_string(assigns.field)

    new_direction = if is_active, do: reverse(current_direction), else: "desc"

    querystring =
      querystring(assigns.params,
        sort_field: assigns.field,
        sort_direction: new_direction
      )

    assigns =
      assigns
      |> assign(:querystring, querystring)
      |> assign(:is_active, is_active)
      |> assign(:current_direction, current_direction)

    ~H"""
    <.link patch={"?#{@querystring}"} class={@class}>
      {@text}
      <%= if @show_icon && @is_active do %>
        <%= if @current_direction == "asc" do %>
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 15l7-7 7 7" />
          </svg>
        <% else %>
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
          </svg>
        <% end %>
      <% end %>
    </.link>
    """
  end

  @doc """
  Builds a querystring from params and options, preserving existing filters.

  ## Parameters
  - params: Current URL parameters map
  - opts: Keyword list of parameters to add/override

  ## Examples

      querystring(%{"search" => "test"}, page: 2)
      # => "page=2&search=test"
  """
  def querystring(params, opts \\ []) do
    # Normalize params to string keys
    params =
      params
      |> normalize_params()
      # Remove framework params
      |> Map.drop(["_csrf_token", "_format"])

    # Build opts map with defaults
    opts_map = %{
      "page" => opts[:page],
      "sort_field" => opts[:sort_field],
      "sort_direction" => opts[:sort_direction]
    }

    params
    |> Map.merge(opts_map)
    |> Enum.filter(fn {_k, v} -> v != nil and v != "" end)
    |> Enum.into(%{})
    |> URI.encode_query()
  end

  @doc """
  Returns the current sort direction for a given field.
  Useful for displaying sort indicators in the UI.

  ## Examples

      current_sort_direction(%{"sort_field" => "name", "sort_direction" => "asc"}, :name)
      # => :asc

      current_sort_direction(%{"sort_field" => "email"}, :name)
      # => nil
  """
  def current_sort_direction(params, field) do
    if params["sort_field"] == to_string(field) do
      case params["sort_direction"] do
        "asc" -> :asc
        "desc" -> :desc
        _ -> nil
      end
    end
  end

  @doc """
  Checks if a field is currently being sorted.
  """
  def sorting_by?(params, field) do
    params["sort_field"] == to_string(field)
  end

  defp reverse("desc"), do: "asc"
  defp reverse("asc"), do: "desc"
  defp reverse(_), do: "desc"

  defp normalize_params(params) when is_map(params) do
    params
    |> Enum.map(fn {k, v} -> {to_string(k), v} end)
    |> Enum.into(%{})
  end
end
