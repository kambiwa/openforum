defmodule OpenforumWeb.Auth.DocumentPreviewController do
  use OpenforumWeb, :controller

  require Logger

  alias Openforum.Context.Documents

  # Bump this whenever the HTML, CSS or footer below changes, so cached PDFs rebuild.
  @template_version 1

  # Read and encoded once at compile time instead of on every request.
  @logo_path Path.expand("../../../priv/static/images/nac/logo.jpg", __DIR__)
  @external_resource @logo_path
  @logo_data_uri "data:image/jpeg;base64," <> Base.encode64(File.read!(@logo_path))

  def show(conn, %{"id" => id}) do

    user = conn.assigns.current_scope.user
    document = Documents.get_document!(user, id)
    etag = etag(document)

    if etag in get_req_header(conn, "if-none-match") do
      conn
      |> put_resp_header("etag", etag)
      |> put_resp_header("cache-control", "private, no-cache")
      |> send_resp(304, "")
    else
      case fetch_pdf(document) do
        {:ok, pdf} ->
          send_pdf(conn, document, pdf, etag)

        {:error, reason} ->
          Logger.error("PDF generation failed for document #{document.id}: #{inspect(reason)}")
          send_resp(conn, 500, "The PDF could not be generated. Please try again.")
      end
    end
  end

  defp send_pdf(conn, document, pdf, etag) do
    disposition = if conn.params["download"], do: "attachment", else: "inline"

    conn
    |> put_resp_content_type("application/pdf")
    |> put_resp_header(
      "content-disposition",
      ~s(#{disposition}; filename="#{slug(document.title)}.pdf")
    )
    # no-cache means "revalidate every time": the browser asks, we answer 304
    # cheaply (no Chrome involved) when nothing changed.
    |> put_resp_header("cache-control", "private, no-cache")
    |> put_resp_header("etag", etag)
    |> send_resp(200, pdf)
  end

  # ── PDF cache (one file per document + version, on disk) ────────────

  defp fetch_pdf(document) do
    path = cache_path(document)

    case File.read(path) do
      {:ok, pdf} -> {:ok, pdf}
      {:error, _} -> render_pdf(document, path)
    end
  end

  defp render_pdf(document, path) do
    result =
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

    case result do
      {:ok, base64} ->
        pdf = Base.decode64!(base64)
        store(document, path, pdf)
        {:ok, pdf}

      other ->
        {:error, other}
    end
  end

  # A cache failure must never break the preview, so every step is non-bang.
  defp store(document, path, pdf) do
    dir = Path.dirname(path)
    tmp = path <> "." <> Integer.to_string(System.unique_integer([:positive])) <> ".tmp"

    with :ok <- File.mkdir_p(dir),
         :ok <- File.write(tmp, pdf),
         :ok <- File.rename(tmp, path) do
      # Drop older versions of this document.
      for old <- Path.wildcard(Path.join(dir, "#{document.id}-*.pdf")), old != path do
        File.rm(old)
      end

      :ok
    else
      _ ->
        File.rm(tmp)
        :ok
    end
  end

  defp cache_path(document) do
    Path.join([System.tmp_dir!(), "openforum_pdf_cache", cache_name(document)])
  end

  defp cache_name(document), do: "#{document.id}-#{version(document)}-v#{@template_version}.pdf"

  defp etag(document), do: ~s("#{cache_name(document)}")

  defp version(%{updated_at: %DateTime{} = dt}), do: DateTime.to_unix(dt, :microsecond)

  defp version(%{updated_at: %NaiveDateTime{} = dt}),
    do: dt |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix(:microsecond)

  defp version(_), do: 0

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
      <header><img src="#{@logo_data_uri}" alt="New Apostolic Church Zambia"></header>
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
