defmodule OpenforumWeb.Unauth.Questions_Answers.Index do
  use OpenforumWeb, :live_view

  # Source: https://nak.org/en/faith/catechism
  @source_url "https://nak.org/en/faith/catechism"

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:mobile_menu_open, false)
      |> assign(:page_title, "Questions & Answers — OpenForum")
      |> assign(:source_url, @source_url)
      |> assign(:documents, documents())
      |> assign(:online_resources, online_resources())

    {:ok, socket}
  end

  @impl true
  def handle_event("toggle_mobile_menu", _params, socket) do
    {:noreply, assign(socket, :mobile_menu_open, !socket.assigns.mobile_menu_open)}
  end

  # NOTE: the nak.org media links carry a signed token and may stop working over
  # time. For a permanent setup, download both PDFs, store them under
  # priv/static/downloads/ and point `url` at "/downloads/<file>.pdf".
  # `page_url` is the stable fallback shown beside each download.
  defp documents do
    [
      %{
        title: "Catechism of the New Apostolic Church",
        description:
          "The doctrinal reference book of the New Apostolic Church and its most systematic description of the Church's doctrine.",
        size: "1.94 MB",
        pages: "517 pages",
        url:
          "https://nak.org/api/media/32683/process?attachment=1&token=6da3e691c425e44e4d4afe5545d176ed%3A1822483509%3A5064725",
        page_url: @source_url,
        cover_class: "bg-[#EAF3F8] text-[#4F7FA8]",
        cover_label: "Catechism of the New Apostolic Church"
      },
      %{
        title: "Catechism of the New Apostolic Church in Questions and Answers",
        description:
          "The same content in a more concentrated form, with simpler wording and fewer theological terms, divided into 750 questions and answers.",
        size: "5.88 MB",
        pages: "144 pages",
        url:
          "https://nak.org/api/media/32685/process?attachment=1&token=7d1166972b1b50aa6764952bbc56fbd4%3A1822483509%3A3328007",
        page_url: @source_url,
        cover_class: "bg-[#0B2E4F] text-white",
        cover_label: "Catechism in Questions and Answers"
      }
    ]
  end

  defp online_resources do
    [
      %{
        icon: "hero-globe-alt",
        title: "Read online",
        description: "Browse the 750 questions and answers directly on faq.nak.org.",
        links: [%{label: "Open faq.nak.org", url: "https://nak.org/en/kennenlernen/faq"}]
      },
      %{
        icon: "hero-device-phone-mobile",
        title: "nacfaq app",
        description: "Carry the questions and answers on your smartphone or tablet.",
        links: [
          %{label: "iOS", url: "https://apps.apple.com/de/app/nacfaq/id1038454619"},
          %{label: "Android", url: "https://play.google.com/store/apps/details?id=de.nak.faq&hl=de"}
        ]
      },
      %{
        icon: "hero-book-open",
        title: "Full Catechism online",
        description: "Study the complete Catechism on catechism.nak.org or in its app.",
        links: [
          %{label: "Open website", url: "https://nak.org/en/kennenlernen/katechismus"},
          %{label: "iOS", url: "https://apps.apple.com/de/app/id635231503"},
          %{
            label: "Android",
            url: "https://play.google.com/store/apps/details?id=de.nak.katechismus"
          }
        ]
      }
    ]
  end
end
