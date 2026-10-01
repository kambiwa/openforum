defmodule Openforum.Bible.Text do
  @moduledoc """
  Loads chapter text from priv/bible/<translation>/<book-slug>.json.

  File format (one file per book, verses as an ordered list per chapter):

      {"1": ["In the beginning...", "And the earth..."], "2": [...]}
  """

  @translations [
    %{id: "kjv", short: "KJV", name: "King James Version"},
    %{id: "web", short: "WEB", name: "World English Bible"}
  ]

  def translations, do: @translations
  def translation_ids, do: Enum.map(@translations, & &1.id)
  def default, do: "kjv"

  def get_translation(id), do: Enum.find(@translations, &(&1.id == id))

  @doc "Translation must be validated by the caller against `translation_ids/0`."
  def chapter(translation, slug, number) when translation in ["kjv", "web"] do
    with {:ok, book} <- load(translation, slug),
         verses when is_list(verses) <- Map.get(book, Integer.to_string(number)) do
      {:ok,
       verses
       |> Enum.with_index(1)
       |> Enum.map(fn {text, n} -> %{number: n, text: text} end)}
    else
      _ -> :error
    end
  end

  defp load(translation, slug) do
    key = {__MODULE__, translation, slug}

    case :persistent_term.get(key, nil) do
      nil ->
        path = Application.app_dir(:openforum, ["priv", "bible", translation, "#{slug}.json"])

        with {:ok, bin} <- File.read(path),
             {:ok, map} <- Jason.decode(bin) do
          :persistent_term.put(key, map)
          {:ok, map}
        else
          _ -> :error
        end

      map ->
        {:ok, map}
    end
  end
end
