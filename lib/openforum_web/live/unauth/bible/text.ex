defmodule Openforum.Bible.Text do
  @moduledoc """
  Loads chapter text from priv/bible/<translation>/<book-slug>.json.

  File format (one file per book, verses as an ordered list per chapter):

      {"1": ["In the beginning...", "And the earth..."], "2": [...]}

  On first read, a book is reshaped into `%{chapter_number => [%{number:, text:}]}`
  and cached in `:persistent_term`, so later requests are a plain map lookup.
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
         verses when is_list(verses) <- Map.get(book, number) do
      {:ok, verses}
    else
      _ -> :error
    end
  end

  defp load(translation, slug) do
    key = {__MODULE__, translation, slug}

    case :persistent_term.get(key, nil) do
      nil -> read(key, translation, slug)
      book -> {:ok, book}
    end
  end

  defp read(key, translation, slug) do
    path = Application.app_dir(:openforum, ["priv", "bible", translation, "#{slug}.json"])

    with {:ok, bin} <- File.read(path),
         {:ok, raw} <- Jason.decode(bin) do
      book =
        Map.new(raw, fn {ch, verses} ->
          {String.to_integer(ch),
           verses
           |> Enum.with_index(1)
           |> Enum.map(fn {text, n} -> %{number: n, text: text} end)}
        end)

      # Re-check so two racing first loads don't both `put`
      # (replacing a persistent_term triggers a global GC pass).
      if :persistent_term.get(key, nil) == nil, do: :persistent_term.put(key, book)
      {:ok, book}
    else
      _ -> :error
    end
  end
end
