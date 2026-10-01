# defmodule Openforum.Bible.Books do
#   @moduledoc "Static list of the 66 canonical books. Swap for a DB query later."

#   # {name, testament, category, chapters}
#   @books [
#     # Old Testament
#     {"Genesis", :old, "Law", 50},
#     {"Exodus", :old, "Law", 40},
#     {"Leviticus", :old, "Law", 27},
#     {"Numbers", :old, "Law", 36},
#     {"Deuteronomy", :old, "Law", 34},
#     {"Joshua", :old, "History", 24},
#     {"Judges", :old, "History", 21},
#     {"Ruth", :old, "History", 4},
#     {"1 Samuel", :old, "History", 31},
#     {"2 Samuel", :old, "History", 24},
#     {"1 Kings", :old, "History", 22},
#     {"2 Kings", :old, "History", 25},
#     {"1 Chronicles", :old, "History", 29},
#     {"2 Chronicles", :old, "History", 36},
#     {"Ezra", :old, "History", 10},
#     {"Nehemiah", :old, "History", 13},
#     {"Esther", :old, "History", 10},
#     {"Job", :old, "Poetry & Wisdom", 42},
#     {"Psalms", :old, "Poetry & Wisdom", 150},
#     {"Proverbs", :old, "Poetry & Wisdom", 31},
#     {"Ecclesiastes", :old, "Poetry & Wisdom", 12},
#     {"Song of Solomon", :old, "Poetry & Wisdom", 8},
#     {"Isaiah", :old, "Major Prophets", 66},
#     {"Jeremiah", :old, "Major Prophets", 52},
#     {"Lamentations", :old, "Major Prophets", 5},
#     {"Ezekiel", :old, "Major Prophets", 48},
#     {"Daniel", :old, "Major Prophets", 12},
#     {"Hosea", :old, "Minor Prophets", 14},
#     {"Joel", :old, "Minor Prophets", 3},
#     {"Amos", :old, "Minor Prophets", 9},
#     {"Obadiah", :old, "Minor Prophets", 1},
#     {"Jonah", :old, "Minor Prophets", 4},
#     {"Micah", :old, "Minor Prophets", 7},
#     {"Nahum", :old, "Minor Prophets", 3},
#     {"Habakkuk", :old, "Minor Prophets", 3},
#     {"Zephaniah", :old, "Minor Prophets", 3},
#     {"Haggai", :old, "Minor Prophets", 2},
#     {"Zechariah", :old, "Minor Prophets", 14},
#     {"Malachi", :old, "Minor Prophets", 4},

#     # New Testament
#     {"Matthew", :new, "Gospels", 28},
#     {"Mark", :new, "Gospels", 16},
#     {"Luke", :new, "Gospels", 24},
#     {"John", :new, "Gospels", 21},
#     {"Acts", :new, "History", 28},
#     {"Romans", :new, "Pauline Epistles", 16},
#     {"1 Corinthians", :new, "Pauline Epistles", 16},
#     {"2 Corinthians", :new, "Pauline Epistles", 13},
#     {"Galatians", :new, "Pauline Epistles", 6},
#     {"Ephesians", :new, "Pauline Epistles", 6},
#     {"Philippians", :new, "Pauline Epistles", 4},
#     {"Colossians", :new, "Pauline Epistles", 4},
#     {"1 Thessalonians", :new, "Pauline Epistles", 5},
#     {"2 Thessalonians", :new, "Pauline Epistles", 3},
#     {"1 Timothy", :new, "Pauline Epistles", 6},
#     {"2 Timothy", :new, "Pauline Epistles", 4},
#     {"Titus", :new, "Pauline Epistles", 3},
#     {"Philemon", :new, "Pauline Epistles", 1},
#     {"Hebrews", :new, "General Epistles", 13},
#     {"James", :new, "General Epistles", 5},
#     {"1 Peter", :new, "General Epistles", 5},
#     {"2 Peter", :new, "General Epistles", 3},
#     {"1 John", :new, "General Epistles", 5},
#     {"2 John", :new, "General Epistles", 1},
#     {"3 John", :new, "General Epistles", 1},
#     {"Jude", :new, "General Epistles", 1},
#     {"Revelation", :new, "Prophecy", 22}
#   ]

#   def all do
#     @books
#     |> Enum.with_index(1)
#     |> Enum.map(fn {{name, testament, category, chapters}, order} ->
#       %{
#         order: order,
#         name: name,
#         slug: name |> String.downcase() |> String.replace(" ", "-"),
#         testament: testament,
#         category: category,
#         chapters: chapters
#       }
#     end)
#   end

#   @doc "Groups an ordered book list into consecutive category groups."
#   def group_by_category(books) do
#     books
#     |> Enum.chunk_by(&{&1.testament, &1.category})
#     |> Enum.map(fn [first | _] = group ->
#       %{category: first.category, books: group}
#     end)
#   end
# end
