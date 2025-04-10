defmodule HtmlToMarkdown.BlockquoteTest do
  use ExUnit.Case

  test "convert simple blockquote" do
    html = """
    <blockquote>
      <p>This is a quote</p>
      <p>With multiple paragraphs</p>
    </blockquote>
    """

    result = HtmlToMarkdown.convert_string(html)
    expected = "> This is a quote\n>\n> With multiple paragraphs"

    IO.puts("Expected:\n#{expected}")
    IO.puts("\nActual:\n#{result.markdown}")

    assert String.trim(result.markdown) == expected
  end
end
