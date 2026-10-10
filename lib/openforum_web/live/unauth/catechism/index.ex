defmodule OpenforumWeb.Unauth.Catechism.Index do
  use OpenforumWeb, :live_view

  # Source: https://nak.org/en/abouttheNAC/catechism
  @source_url "https://nak.org/en/abouttheNAC/catechism"

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:mobile_menu_open, false)
      |> assign(:page_title, "Catechism — OpenForum")
      |> assign(:source_url, @source_url)
      |> assign(:chapters, chapters())
      |> assign(:introduction, introduction())
      |> select_chapter("introduction")

    {:ok, socket}
  end

  @impl true
  def handle_event("toggle_mobile_menu", _params, socket) do
    {:noreply, assign(socket, :mobile_menu_open, !socket.assigns.mobile_menu_open)}
  end

  def handle_event("select_chapter", %{"id" => id}, socket) do
    {:noreply, select_chapter(socket, id)}
  end

  # Falls back to the introduction when the id is unknown.
  defp select_chapter(socket, id) do
    chapters = socket.assigns.chapters
    index = Enum.find_index(chapters, &(&1.id == id)) || 0

    socket
    |> assign(:active_id, Enum.at(chapters, index).id)
    |> assign(:current, Enum.at(chapters, index))
    |> assign(:prev_chapter, if(index > 0, do: Enum.at(chapters, index - 1)))
    |> assign(:next_chapter, Enum.at(chapters, index + 1))
  end

  # Short summaries are written for OpenForum. The full Catechism text is
  # published by the New Apostolic Church International; each chapter links to it.
  defp chapters do
    base = @source_url <> "?id="

    [
      %{
        id: "introduction",
        number: nil,
        title: "Introduction",
        summary:
          "Why the Catechism exists, what the word means, how the book is organised and what it is meant to do.",
        url: base <> "ec80bb75-00b3-4e0c-8447-00890818a16b"
      },
      %{
        id: "revelations-of-god",
        number: 1,
        title: "The revelations of God",
        summary: "How God reveals Himself, and the place of Holy Scripture in that revelation.",
        url: base <> "27bca24f-ad84-4841-99f9-67c2cf2d4a2a"
      },
      %{
        id: "the-creed",
        number: 2,
        title: "The Creed",
        summary: "An explanation of the New Apostolic Creed, article by article.",
        url: base <> "6f4a0d58-80ec-40aa-955c-21fb326b5bf0"
      },
      %{
        id: "triune-god",
        number: 3,
        title: "The triune God",
        summary:
          "Faith in God the Father, God the Son and God the Holy Spirit, including beliefs shared across Christian denominations.",
        url: base <> "9511c876-157b-40bb-8a5f-1ab21fb596c8"
      },
      %{
        id: "mankind-in-need-of-redemption",
        number: 4,
        title: "Mankind in need of redemption",
        summary:
          "The condition of humanity before God, the fall into sin, the need for redemption, and how the Law relates to the gospel.",
        url: base <> "e66f69d2-e746-427f-8c62-d30c075cd944"
      },
      %{
        id: "gods-commandments",
        number: 5,
        title: "God's commandments",
        summary:
          "The Ten Commandments, and why faith shapes how a believer lives, not only what they believe.",
        url: base <> "8c57b16c-293d-421f-886a-d1787bd053d7"
      },
      %{
        id: "church-of-jesus-christ",
        number: 6,
        title: "The church of Jesus Christ",
        summary:
          "What the church is, the forms it takes, and how the New Apostolic Church understands itself within it.",
        url: base <> "f34dcda7-b703-40ed-b572-9f971f08e085"
      },
      %{
        id: "ministry",
        number: 7,
        title: "Ministry",
        summary:
          "The meaning of ministry, and the Apostle ministry as the source of the other ministries.",
        url: base <> "8ab0e8aa-f3e4-4731-aba3-ced21ea292ab"
      },
      %{
        id: "sacraments",
        number: 8,
        title: "The sacraments",
        summary: "Holy Baptism with water, Holy Communion and Holy Sealing.",
        url: base <> "2562686f-9511-48e7-944a-ecd5b63889dc"
      },
      %{
        id: "life-after-death",
        number: 9,
        title: "Life after death",
        summary:
          "What happens after death, the relationship between the departed and God, and the question of salvation beyond death.",
        url: base <> "c3d01408-02f8-4b14-97f0-5de641c9fab6"
      },
      %{
        id: "future-things",
        number: 10,
        title: "The doctrine of future things",
        summary:
          "The return of Christ and God's plan of salvation, including the New Apostolic goal of faith.",
        url: base <> "642f87b1-e392-4f35-be4d-f542d712461d"
      },
      %{
        id: "history-of-christianity",
        number: 11,
        title: "From the history of Christianity",
        summary: "Key moments in the history of Christianity and of the New Apostolic Church.",
        url: base <> "34746188-241a-4763-96b2-8a619c1ae586"
      },
      %{
        id: "divine-service",
        number: 12,
        title: "Divine service, acts of blessing, and pastoral care",
        summary: "How the congregation worships, receives blessings and is cared for.",
        url: base <> "2fbbf010-dc55-4d05-9b9e-ebc6fcbadb12"
      },
      %{
        id: "life-of-faith",
        number: 13,
        title: "New Apostolic Christians and their life of faith",
        summary: "How faith is put into practice in everyday life.",
        url: base <> "8c5c37ad-b4f7-44be-ab2d-bb6853bb7e1c"
      },
      %{
        id: "appendix",
        number: nil,
        title: "Appendix",
        summary: "Supporting material at the end of the Catechism.",
        url: base <> "828dc3fa-c849-4098-930a-4f8fb5ca9d3b"
      }
    ]
  end

  defp introduction do
    [
      %{
        heading: "Professions of faith in the New Testament",
        body:
          "Christians have always been asked to explain and share what they believe. The New Testament already contains short statements of faith that centre on Jesus as the risen Lord. These statements were used to teach those preparing for baptism and to keep the message of Christ true to its source."
      },
      %{
        heading: "What \"Catechism\" means",
        body:
          "The word comes from Greek and was first used for teaching people who were preparing for baptism with water. A catechism sets out what Christians believe and how that belief shapes the way they live. Its foundation is Holy Scripture, and it presents the core message of both the Old and New Testaments."
      },
      %{
        heading: "How the book is organised",
        body:
          "The Catechism begins with God's revelation and Holy Scripture, then moves through the Creed, the Trinity, humanity's need of redemption and the commandments. It continues with the church, ministry and the sacraments, then turns to life after death and future things. It closes with history, worship and daily life."
      },
      %{
        heading: "What the Catechism is for",
        body:
          "It serves as a basis for Church instruction and ministers' meetings, helps keep doctrinal statements consistent across languages and cultures, and deepens the faith of New Apostolic Christians. It also shows both what New Apostolic doctrine shares with other churches and where it differs, as a starting point for dialogue. It is an invitation to members and to anyone interested to get to know the doctrine."
      }
    ]
  end

  attr :chapters, :list, required: true
  attr :active_id, :string, required: true

  defp chapter_nav(assigns) do
    ~H"""
    <nav aria-label="Catechism chapters">
      <ul class="space-y-1">
        <li :for={chapter <- @chapters}>
          <button
            type="button"
            phx-click="select_chapter"
            phx-value-id={chapter.id}
            aria-current={@active_id == chapter.id && "page"}
            class={[
              "flex w-full items-baseline gap-3 rounded-md px-3 py-2 text-left text-sm transition-colors",
              @active_id == chapter.id && "bg-[#0B2E4F] font-medium text-white",
              @active_id != chapter.id && "text-[#0B2E4F] hover:bg-[#EAF3F8]"
            ]}
          >
            <span :if={chapter.number} class="w-5 shrink-0 text-xs opacity-70">{chapter.number}</span>
            <span :if={!chapter.number} class="w-5 shrink-0"></span>
            <span>{chapter.title}</span>
          </button>
        </li>
      </ul>
    </nav>
    """
  end
end
