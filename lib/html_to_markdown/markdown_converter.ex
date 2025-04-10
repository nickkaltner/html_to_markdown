# lib/html_to_markdown/markdown_converter.ex
defmodule HtmlToMarkdown.MarkdownConverter do
  @moduledoc """
  A markdown converter for HTML content.

  Changes include:
  - Altering the default heading style to use '#', '##', etc.
  - Removing JavaScript hyperlinks.
  - Truncating images with large data:uri sources.
  - Ensuring URIs are properly escaped, and do not conflict with Markdown syntax.
  """

  alias HtmlEntities

  @doc """
  Convert an HTML document (as parsed by Floki) to Markdown.
  """
  def convert_soup(html_tree, opts \\ []) do
    html_tree
    |> process_node(opts)
    |> process_result()
  end

  defp process_result(result) do
    result
    |> to_string()
    |> String.trim_leading()
    |> normalize_newlines()
  end

  # Normalize excessive newlines to make output more consistent
  defp normalize_newlines(text) do
    text
    # Replace 3+ newlines with 2
    |> String.replace(~r/\n{3,}/, "\n\n")
  end

  defp process_node(nodes, opts) when is_list(nodes) do
    # Use Enum.map_join as suggested by Credo
    Enum.map_join(nodes, &process_node(&1, opts))
  end

  # Process text node
  defp process_node({:text, content}, _opts) do
    content
  end

  # Process heading (h1-h6) nodes
  defp process_node({"h" <> n, _attrs, children}, opts)
       when n in ["1", "2", "3", "4", "5", "6"] do
    heading_level = String.to_integer(n)
    prefix = String.duplicate("#", heading_level)

    # Convert children to text
    inner_content = process_node(children, opts) |> String.trim()

    "\n#{prefix} #{inner_content}\n"
  end

  # Process link (a) nodes
  defp process_node({"a", attrs, children}, opts) do
    inner_content = process_node(children, opts)

    # Skip if no content
    if inner_content == "", do: "", else: process_link(attrs, inner_content, opts)
  end

  # Process image (img) nodes
  defp process_node({"img", attrs, _children}, opts) do
    process_image(attrs, opts)
  end

  # Process paragraph (p) nodes
  defp process_node({"p", _attrs, children}, opts) do
    inner_content = process_node(children, opts)

    content = String.trim(inner_content)

    "\n\n#{content}\n"
  end

  # Process unordered list (ul) nodes
  defp process_node({"ul", _attrs, children}, opts) do
    is_in_li = Keyword.get(opts, :in_li, false)

    if is_in_li do
      "\n\n" <> process_list_items(children, opts)
    else
      "\n" <> process_list_items(children, opts) <> "\n"
    end
  end

  # Process ordered list (ol) nodes
  defp process_node({"ol", _attrs, children}, opts) do
    is_in_li = Keyword.get(opts, :in_li, false)
    items_content = process_ordered_list_items(children, opts)

    if is_in_li do
      "\n\n" <> items_content
    else
      "\n" <> items_content <> "\n"
    end
  end

  # Process list item (li) nodes
  defp process_node({"li", _attrs, children}, opts) do
    {nested_lists, other_content} =
      Enum.split_with(children, fn
        {"ul", _, _} -> true
        {"ol", _, _} -> true
        _ -> false
      end)

    content = process_node(other_content, opts)

    nested_content =
      if nested_lists != [] do
        nested_opts = opts |> Keyword.put(:in_li, true)
        process_node(nested_lists, nested_opts)
      else
        ""
      end

    marker = Keyword.get(opts, :list_marker, "- ")
    "#{marker}#{String.trim(content)}#{nested_content}\n"
  end

  # Process bold (strong) nodes
  defp process_node({"strong", _attrs, children}, opts) do
    "**#{process_node(children, opts)}**"
  end

  # Process italic (em) nodes
  defp process_node({"em", _attrs, children}, opts) do
    "*#{process_node(children, opts)}*"
  end

  # Process code-only <pre><code> blocks to preserve whitespace exactly
  defp process_node({"pre", _attrs, [{"code", _code_attrs, code_children}]}, _opts) do
    code_text =
      code_children
      |> Enum.map_join("", fn
        {:text, content} -> content
        node -> process_node(node, [])
      end)
      |> HtmlEntities.decode()
      |> String.trim_trailing()

    "\n```\n" <> code_text <> "\n```\n"
  end

  # Process generic <pre> blocks: flatten out spans/tags, decode, and preserve original spacing
  defp process_node({"pre", _attrs, children}, _opts) do
    code_text =
      children
      |> Floki.text()
      |> HtmlEntities.decode()
      |> String.trim_trailing()

    "\n```\n" <> code_text <> "\n```\n"
  end

  # Handle div wrappers by raw snippet attribute or unwrap children
  defp process_node({"div", attrs, children}, opts) do
    # Use raw snippet if provided via attribute
    case List.keyfind(attrs, "data-snippet-clipboard-copy-content", 0) do
      {_, raw} when is_binary(raw) ->
        decoded = HtmlEntities.decode(raw) |> String.trim()
        "\n```\n" <> decoded <> "\n```\n"

      _ ->
        # unwrap other divs to find nested <pre>
        process_node(children, opts)
    end
  end

  # Process inline code (code) nodes
  defp process_node({"code", _attrs, children}, opts) do
    parent = Keyword.get(opts, :parent)

    inner_content =
      if parent == "pre" do
        # Preserve operator spacing in code blocks
        Enum.map_join(children, " ", &process_node(&1, opts))
      else
        process_node(children, opts)
      end

    if parent == "pre", do: inner_content, else: "`#{inner_content}`"
  end

  # Process span nodes
  defp process_node({"span", _attrs, children}, opts), do: process_node(children, opts)

  # Process blockquote nodes
  defp process_node({"blockquote", _attrs, children}, opts) do
    inner_content = process_node(children, opts)

    paragraphs =
      inner_content
      |> String.trim()
      |> String.split(~r/\n{2,}/)
      |> Enum.map(&String.trim/1)
      |> Enum.filter(&(&1 != ""))

    formatted =
      paragraphs
      |> Enum.map(fn para ->
        "> " <> String.replace(para, ~r/\n/, "\n> ")
      end)
      |> Enum.join("\n>\n")

    formatted
  end

  # Process table nodes
  defp process_node({"table", _attrs, children}, opts) do
    thead = Enum.find(children, &match?({"thead", _, _}, &1))
    tbody = Enum.find(children, &match?({"tbody", _, _}, &1))

    header_content = if thead, do: process_node(thead, opts), else: ""

    body_content =
      cond do
        tbody -> process_node(tbody, opts)
        true -> process_table_rows(children, opts, "td")
      end

    "\n\n#{header_content}#{body_content}\n"
  end

  defp process_node({"thead", _attrs, children}, opts) do
    header_tr = Enum.find(children, &match?({"tr", _, _}, &1))

    if header_tr do
      {_tag, _a, tr_children} = header_tr
      ths = Enum.filter(tr_children, fn
        {t, _, _} -> t == "th"
        _ -> false
      end)
      count = length(ths)
      row = process_node(header_tr, Keyword.put(opts, :cell_tag, "th"))
      sep = "| " <> Enum.join(List.duplicate("---", count), " | ") <> " |\n"
      row <> sep
    else
      ""
    end
  end

  defp process_node({"tbody", _attrs, children}, opts),
    do: process_table_rows(children, opts, "td")

  defp process_node({"tr", _attrs, children}, opts) do
    tag = Keyword.get(opts, :cell_tag, "td")
    cells = Enum.filter(children, fn
      {t, _, _} when t == tag or t == "th" -> true
      _ -> false
    end)
    content = cells |> Enum.map(&process_node(&1, opts)) |> Enum.join(" | ")
    "| #{content} |\n"
  end

  defp process_node({"th", _attrs, children}, opts), do: String.trim(process_node(children, opts))
  defp process_node({"td", _attrs, children}, opts), do: String.trim(process_node(children, opts))

  # Definition list (dl, dt, dd)
  defp process_node({"dl", _attrs, children}, opts),
    do: "\n\n" <> process_definition_items(children, opts) <> "\n"

  defp process_node({"dt", _attrs, children}, opts), do: "**#{process_node(children, opts)}**\n"
  defp process_node({"dd", _attrs, children}, opts), do: ": #{process_node(children, opts)}\n\n"

  # Skip script, style, button, form, input, nav, and footer
  defp process_node({tag, _attrs, _}, _opts)
       when tag in ["script", "style", "button", "form", "input", "nav", "footer"],
       do: ""

  # Fallbacks
  defp process_node({_t, _a, children}, opts), do: process_node(children, opts)
  defp process_node(node, _opts) when is_binary(node), do: node
  defp process_node(_, _), do: ""

  # Helpers: lists, tables, definitions, links, images, attrs
  defp process_list_items(items, opts) do
    items
    |> Enum.filter(fn
      {"li", _, _} -> true
      _ -> false
    end)
    |> Enum.map_join(&process_node(&1, Keyword.put(opts, :list_marker, "- ")))
  end

  defp process_ordered_list_items(items, opts) do
    items
    |> Enum.filter(fn
      {"li", _, _} -> true
      _ -> false
    end)
    |> Enum.with_index(1)
    |> Enum.map_join(fn {item, idx} ->
      process_node(item, Keyword.put(opts, :list_marker, "#{idx}. "))
    end)
  end

  defp process_table_rows(rows, opts, tag) do
    rows
    |> Enum.filter(fn
      {"tr", _, _} -> true
      _ -> false
    end)
    |> Enum.map_join(&process_node(&1, Keyword.put(opts, :cell_tag, tag)))
  end

  defp process_definition_items(items, opts) do
    items
    |> Enum.filter(fn
      {"dt", _, _} -> true
      {"dd", _, _} -> true
      _ -> false
    end)
    |> Enum.map_join(&process_node(&1, opts))
  end

  defp process_link(attrs, text, _opts) do
    # Trim whitespace and normalize internal whitespace/newlines in link text
    text =
      text
      |> String.trim()
      |> String.replace(~r/\s*\n\s*/, " ")
      |> String.replace(~r/ {2,}/, " ")

    href = get_attr_value(attrs, "href")
    title = get_attr_value(attrs, "title")

    cond do
      href == nil ->
        text

      !valid_url_scheme?(href) ->
        text

      true ->
        href = escape_url(href)
        title_part = if title, do: " \"#{escape_title(title)}\"", else: ""
        "[#{text}](#{href}#{title_part})"
    end
  end

  defp process_image(attrs, opts) do
    alt = get_attr_value(attrs, "alt") || ""
    src = get_attr_value(attrs, "src") || ""
    title = get_attr_value(attrs, "title") || ""
    keep = Keyword.get(opts, :keep_data_uris, false)

    src =
      if String.starts_with?(src, "data:") and not keep do
        [scheme | _] = String.split(src, ",")
        "#{scheme}..."
      else
        src
      end

    title_part = if title != "", do: " \"#{escape_title(title)}\"", else: ""
    "![#{alt}](#{src}#{title_part})"
  end

  defp get_attr_value(attrs, key) do
    Enum.find_value(attrs, fn
      {^key, v} -> v
      _ -> nil
    end)
  end

  defp valid_url_scheme?(url) do
    case URI.parse(url) do
      %URI{scheme: s} when s in ["http", "https", "file"] -> true
      %URI{scheme: nil} -> true
      _ -> false
    end
  end

  defp escape_url(url) do
    case URI.parse(url) do
      uri = %URI{path: path} when is_binary(path) ->
        processed_path = path |> URI.decode() |> URI.encode()
        %{uri | path: processed_path} |> URI.to_string()

      uri = %URI{} ->
        # No valid path to process, return as-is
        URI.to_string(uri)
    end
  end

  defp escape_title(title) do
    String.replace(title, "\"", "\\\"")
  end
end
