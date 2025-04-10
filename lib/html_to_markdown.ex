defmodule HtmlToMarkdown do
  @moduledoc """
  Documentation for `HtmlToMarkdown`.

  This library converts HTML content to Markdown format.

  """

  alias HtmlToMarkdown.{DocumentConverterResult, HtmlConverter, StreamInfo}

  @doc """
  Convert an HTML string to Markdown.

  ## Parameters

    * `html` - The HTML content as a string
    * `opts` - Options for conversion (see below)

  ## Options

    * `:url` - The URL of the HTML content (optional)
    * `:keep_data_uris` - Whether to keep data URIs in images (default: false)

  ## Examples

      iex> result = HtmlToMarkdown.convert_string("<h1>Hello World</h1>")
      iex> result.markdown
      "# Hello World\\n"
      iex> result.title
      nil

  """
  @spec convert_string(String.t(), keyword()) :: DocumentConverterResult.t()
  def convert_string(html, opts \\ []) do
    new_html =
      Regex.replace(~r/>( +)</, html, fn _, spaces ->
        ">" <> String.duplicate("&#32;", String.length(spaces)) <> "<"
      end)

    # Preserve newlines between tags using LF entity instead of CR
    new_html = String.replace(new_html, ~r/>[\n\r]+</, ">&#10;<")
    HtmlConverter.convert_string(new_html, opts)
  end

  @doc """
  Convert an HTML file to Markdown.

  Returns `{:ok, result}` on success, where `result` is a `DocumentConverterResult`,
  or `{:error, reason}` if the file cannot be opened or processed.

  ## Parameters

    * `file_path` - Path to the HTML file
    * `opts` - Options for conversion (see below)

  ## Options

    * `:keep_data_uris` - Whether to keep data URIs in images (default: false)

  """
  @spec convert_file(String.t(), keyword()) ::
          {:ok, DocumentConverterResult.t()} | {:error, term()}
  def convert_file(file_path, opts \\ []) do
    # Changed from `with` to `case` as suggested by Credo
    case File.open(file_path, [:read]) do
      {:ok, file} ->
        try do
          extension = Path.extname(file_path)

          stream_info = %StreamInfo{
            mimetype: "text/html",
            extension: extension,
            charset: "utf-8"
          }

          result = HtmlConverter.convert(file, stream_info, opts)
          {:ok, result}
        after
          File.close(file)
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Extract the plain text from HTML content, converting it to Markdown first.

  ## Parameters

    * `html` - The HTML content as a string
    * `opts` - Options for conversion

  ## Examples

      iex> HtmlToMarkdown.html_to_text("<h1>Hello</h1><p>World</p>")
      "# Hello\\n\\nWorld\\n"

  """
  @spec html_to_text(String.t(), keyword()) :: String.t()
  def html_to_text(html, opts \\ []) do
    html
    |> convert_string(opts)
    |> Map.get(:markdown)
  end
end
