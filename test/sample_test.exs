defmodule SampleTest do
  use ExUnit.Case
  alias HtmlToMarkdown.DocumentConverterResult

  test "convert floki sample file to markdown" do
    path = Path.join(__DIR__, "samples/floki.html")

    assert {:ok, %DocumentConverterResult{markdown: markdown, title: title}} =
             HtmlToMarkdown.convert_file(path)

    # Ensure markdown content is generated
    assert is_binary(markdown) and byte_size(markdown) > 0
    # Verify the extracted title matches the HTML title
    assert title ==
             "GitHub - philss/floki: Floki is a simple HTML parser that enables search for nodes using CSS selectors."

    # Ensure the sample contains the specific section header
    assert markdown =~ "## Suppressing log messages"
  end
end
