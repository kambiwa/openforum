defmodule Mix.Tasks.Bible.Import do
  @shortdoc "Splits a whole-Bible JSON file into priv/bible/<translation>/<slug>.json"

  @moduledoc """
  Usage:

      mix bible.import kjv path/to/en_kjv.json

  The source must be a JSON array of 66 books in canonical order, where each
  book is an object with a "chapters" key holding a list of chapters, and each
  chapter is a list of verse strings (the thiagobodruk/bible layout).

  The task checks the book count and every book's chapter count against
  `Openforum.Bible.Books` and stops without writing anything if they differ.
  """

  use Mix.Task

  alias Openforum.Bible.Books

  @impl Mix.Task
  def run([translation, source]) do
    Mix.Task.run("compile")

    books = Books.all()

    raw =
      source
      |> File.read!()
      # some distributions ship with a UTF-8 byte order mark
      |> String.trim_leading("\uFEFF")
      |> Jason.decode!()

    if length(raw) != length(books) do
      Mix.raise("Expected #{length(books)} books, found #{length(raw)}")
    end

    # Validate everything first so a bad source never leaves a half-written folder.
    prepared =
      Enum.zip_with(books, raw, fn book, entry ->
        chapters = Map.fetch!(entry, "chapters")

        if length(chapters) != book.chapters do
          Mix.raise(
            "#{book.name}: expected #{book.chapters} chapters, found #{length(chapters)}"
          )
        end

        data =
          chapters
          |> Enum.with_index(1)
          |> Map.new(fn {verses, n} -> {Integer.to_string(n), verses} end)

        {book.slug, data}
      end)

    out = Path.join(["priv", "bible", translation])
    File.mkdir_p!(out)

    Enum.each(prepared, fn {slug, data} ->
      File.write!(Path.join(out, "#{slug}.json"), Jason.encode!(data))
    end)

    Mix.shell().info("Wrote #{length(prepared)} books to #{out}")
  end

  def run(_), do: Mix.raise("Usage: mix bible.import <translation-id> <source.json>")
end
