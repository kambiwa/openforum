defmodule OpenforumWeb.Auth.DocumentPreviewController do
  use OpenforumWeb, :controller

  alias Openforum.Context.Documents

  @logo_path "priv/static/images/nac/logo.jpg"

  def show(conn, %{"id" => id}) do
    user = conn.assigns.current_scope.user
    document = Documents.get_document!(user, id)

    {:ok, pdf_base64} =
      ChromicPDF.print_to_pdf({:html, html(document)},
        print_to_pdf: %{
          displayHeaderFooter: true,
          headerTemplate: "<span></span>",
          footerTemplate: footer(document),
          paperWidth: 8.27,
          paperHeight: 11.69,
          marginTop: 0.6,
          marginBottom: 0.9,
          marginLeft: 0.8,
          marginRight: 0.8
        }
      )

    disposition = if conn.params["download"], do: "attachment", else: "inline"

    conn
    |> put_resp_content_type("application/pdf")
    |> put_resp_header(
      "content-disposition",
      ~s(#{disposition}; filename="#{slug(document.title)}.pdf")
    )
    |> send_resp(200, Base.decode64!(pdf_base64))
  end

  # ── HTML (standalone: Tailwind classes are NOT available here) ──────

  defp html(doc) do
    """
    <!doctype html>
    <html><head><meta charset="utf-8">
    <style>
      body { font-family: Georgia, "Times New Roman", serif; color: #252525; font-size: 11pt; line-height: 1.6; margin: 0; }
      header { display: flex; justify-content: flex-end; border-bottom: 1px solid #E5E7EB; padding-bottom: 12px; }
      header img { height: 56px; }
      h1.title { font-size: 20pt; font-weight: 500; margin: 36px 0 6px; }
      .summary { font-style: italic; color: #6B7280; font-size: 10pt; margin: 0 0 24px; }
      .body { text-align: justify; overflow-wrap: break-word; }
      .body p { margin: 0 0 12px; }
      .body h1, .body h2 { margin: 16px 0 8px; }
      .body ul, .body ol { padding-left: 24px; margin: 0 0 12px; }
      .body img { max-width: 100%; }
      .body pre { background: #F3F4F6; padding: 10px; white-space: pre-wrap; font-size: 9pt; }
      .body a { color: #1769AA; }
    </style></head>
    <body>
      <header><img src="#{logo_data_uri()}" alt="New Apostolic Church Zambia"></header>
      <h1 class="title">#{esc(doc.title)}</h1>
      #{if doc.summary, do: ~s(<p class="summary">#{esc(doc.summary)}</p>), else: ""}
      <div class="body">#{HtmlSanitizeEx.basic_html(doc.body || "")}</div>
    </body></html>
    """
  end

  # Chrome footer templates need inline styles and an explicit font-size.
  defp footer(doc) do
    """
    <div style="width:100%; font-size:8px; color:#6B7280; padding:0 0.8in; font-family:sans-serif;">
      <div style="border-top:1px solid #E5E7EB; padding-top:6px; display:flex; justify-content:space-between;">
        <span><b style="color:#252525">#{esc(doc.title)}</b> · #{format_date(doc.updated_at)} · #{language(doc)}</span>
        <span>Page <span class="pageNumber"></span> of <span class="totalPages"></span></span>
      </div>
    </div>
    """
  end

  defp logo_data_uri do
    path = Application.app_dir(:openforum, @logo_path |> String.replace_prefix("priv/", "priv/"))
    "data:image/jpeg;base64," <> Base.encode64(File.read!(path))
  end

  defp esc(nil), do: ""
  defp esc(text), do: text |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()

  defp format_date(nil), do: ""
  defp format_date(dt), do: "#{dt.day} #{Calendar.strftime(dt, "%B %Y")}"

  defp language(doc) do
    case Map.get(doc, :language) do
      l when is_binary(l) and l != "" -> l
      _ -> "English"
    end
  end

  defp slug(title) do
    (title || "document")
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "-")
    |> String.trim("-")
  end
end
