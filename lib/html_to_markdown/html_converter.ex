defmodule HtmlToMarkdown.HtmlConverter do
  @moduledoc """
  HTML to Markdown converter.
  Equivalent to HtmlConverter in the Python implementation.
  """

  @behaviour HtmlToMarkdown.DocumentConverter

  # Reordered aliases alphabetically
  alias HtmlToMarkdown.{MarkdownConverter, DocumentConverterResult, StreamInfo}

  @accepted_mime_type_prefixes [
    "text/html",
    "application/xhtml"
  ]

  @accepted_file_extensions [
    ".html",
    ".htm"
  ]

  @impl true
  def accepts(_file_stream, stream_info, _opts \\ []) do
    mimetype = (stream_info.mimetype || "") |> String.downcase()
    extension = (stream_info.extension || "") |> String.downcase()

    extension in @accepted_file_extensions ||
      Enum.any?(@accepted_mime_type_prefixes, &String.starts_with?(mimetype, &1))
  end

  @impl true
  def convert(file_stream, stream_info, opts \\ []) do
    # Read the file contents
    html_content = IO.read(file_stream, :eof)

    # Convert the HTML string
    convert_html_content(html_content, stream_info, opts)
  end

  @doc """
  Convenience method to convert HTML string to markdown.
  """
  def convert_string(html_content, opts \\ []) do
    url = Keyword.get(opts, :url)

    # Create stream info
    stream_info = %StreamInfo{
      mimetype: "text/html",
      extension: ".html",
      charset: "utf-8",
      url: url
    }

    # Convert
    convert_html_content(html_content, stream_info, opts)
  end

  # Helper to convert HTML content to Markdown
  defp convert_html_content(html_content, stream_info, opts) do
    # Determine encoding
    encoding = stream_info.charset || "utf-8"

    # Parse the HTML - use the correct parsing mode for the content
    html_tree =
      case parse_html(html_content, encoding) do
        {:ok, tree} -> tree
        {:error, _} -> Floki.parse_fragment!(html_content)
      end

    # Remove javascript and style blocks
    html_tree = Floki.filter_out(html_tree, "script")
    html_tree = Floki.filter_out(html_tree, "style")

    # Get the title if it exists
    title = find_title(html_tree)

    # Get the body element if it exists, otherwise use the whole document
    body = find_body(html_tree)

    # Convert to markdown
    markdown_content =
      MarkdownConverter.convert_soup(body, opts)
      |> strip_whitespace_at_start_of_lines()

    # Create the result
    %DocumentConverterResult{
      markdown: markdown_content,
      title: title
    }
  end

  # Parse HTML trying different approaches
  defp parse_html(html_content, encoding) do
    # First try to parse as a document
    case Floki.parse_document(decode_html(html_content, encoding)) do
      {:ok, tree} ->
        {:ok, tree}

      {:error, _} ->
        # If that fails, try as a fragment
        case Floki.parse_fragment(decode_html(html_content, encoding)) do
          {:ok, tree} -> {:ok, tree}
          error -> error
        end
    end
  end

  # Find title in the HTML tree
  defp find_title(html_tree) do
    # First try to find the regular title tag
    case Floki.find(html_tree, "title") do
      [title_element | _] ->
        Floki.text(title_element)

      _ ->
        # If no title tag found, check for Open Graph title meta tag
        case Floki.find(html_tree, "meta[property='og:title']") do
          [og_title_element | _] ->
            # Extract the content attribute from the og:title meta tag
            og_title_element
            |> Floki.attribute("content")
            |> List.first()

          _ ->
            nil
        end
    end
  end

  # Find the body or equivalent content in the HTML tree
  defp find_body(html_tree) do
    case Floki.find(html_tree, "body") do
      [body | _] ->
        body

      _ ->
        # If no body found, return the full tree for processing
        html_tree
    end
  end

  # Helper function to handle different encodings
  defp decode_html(html_content, _encoding) do
    # In a real implementation, we would handle different encodings here
    # For simplicity, we'll assume UTF-8 for now
    html_content
  end

  @doc false
  def strip_whitespace_at_start_of_lines(markdown) do
    # Remove leading whitespace from each line, but preserve indentation inside fenced code blocks
    lines = String.split(markdown, "\n")

    {processed, _in_block} =
      Enum.reduce(lines, {[], false}, fn line, {acc, in_block} ->
        cond do
          String.starts_with?(line, "```") ->
            {[line | acc], !in_block}

          in_block ->
            {[line | acc], in_block}

          true ->
            {[String.trim_leading(line) | acc], in_block}
        end
      end)

    processed
    |> Enum.reverse()
    |> Enum.join("\n")
  end
end
