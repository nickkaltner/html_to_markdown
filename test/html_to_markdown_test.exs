defmodule HtmlToMarkdownTest do
  use ExUnit.Case
  doctest HtmlToMarkdown

  test "convert basic headings" do
    html = """
    <h1>Heading 1</h1>
    <h2>Heading 2</h2>
    <h3>Heading 3</h3>
    <h4>Heading 4</h4>
    <h5>Heading 5</h5>
    <h6>Heading 6</h6>
    """

    result = HtmlToMarkdown.convert_string(html)

    expected =
      """
      # Heading 1

      ## Heading 2

      ### Heading 3

      #### Heading 4

      ##### Heading 5

      ###### Heading 6
      """

    assert result.markdown == expected
  end

  test "convert paragraphs" do
    html = """
    <p>First paragraph</p>
    <p>Second paragraph with <strong>bold</strong> and <em>italic</em> text</p>
    """

    result = HtmlToMarkdown.convert_string(html)

    expected =
      """
      First paragraph

      Second paragraph with **bold** and *italic* text
      """

    assert result.markdown == expected
  end

  test "convert links" do
    html = """
    <p>
      <a href="https://example.com">Normal link</a>
      <a href="https://example.com" title="Link title">Link with title</a>
      <a href="javascript:alert('test')">JavaScript link</a>
    </p>
    """

    result = HtmlToMarkdown.convert_string(html)

    # JavaScript links should be filtered out
    assert result.markdown =~ "[Normal link](https://example.com)"
    assert result.markdown =~ "[Link with title](https://example.com \"Link title\")"
    refute result.markdown =~ "javascript:alert"
  end

  test "convert images" do
    html = """
    <p>
      <img src="image.jpg" alt="Image alt">
      <img src="image.jpg" alt="Image with title" title="Image title">
      <img src="data:image/png;base64,ABC123456789" alt="Data URI">
    </p>
    """

    # Test with data URIs kept
    result1 = HtmlToMarkdown.convert_string(html, keep_data_uris: true)
    assert result1.markdown =~ "![Image alt](image.jpg)"
    assert result1.markdown =~ "![Image with title](image.jpg \"Image title\")"
    assert result1.markdown =~ "![Data URI](data:image/png;base64,ABC123456789)"

    # Test with data URIs truncated (default)
    result2 = HtmlToMarkdown.convert_string(html)
    assert result2.markdown =~ "![Image alt](image.jpg)"
    assert result2.markdown =~ "![Image with title](image.jpg \"Image title\")"
    assert result2.markdown =~ "![Data URI](data:image/png;base64...)"
  end

  test "convert lists" do
    html = """
    <ul>
      <li>Item 1</li>
      <li>Item 2
        <ul>
          <li>Nested item 1</li>
          <li>Nested item 2</li>
        </ul>
      </li>
      <li>Item 3</li>
    </ul>
    """

    result = HtmlToMarkdown.convert_string(html)

    expected =
      """
      - Item 1
      - Item 2

      - Nested item 1
      - Nested item 2

      - Item 3
      """
      |> String.trim()

    assert String.trim(result.markdown) == expected
  end

  test "convert ordered lists" do
    html = """
    <ol>
      <li>First item</li>
      <li>Second item
        <ol>
          <li>Nested item A</li>
          <li>Nested item B</li>
        </ol>
      </li>
      <li>Third item</li>
    </ol>
    """

    result = HtmlToMarkdown.convert_string(html)

    expected =
      """
      1. First item
      2. Second item

      1. Nested item A
      2. Nested item B

      3. Third item
      """
      |> String.trim()

    assert String.trim(result.markdown) == expected
  end

  test "convert ordered lists with extraneous text nodes" do
    html = """
    <ol>
      Some intro text:
      <li>First</li>
      <li>Second</li>
    </ol>
    """

    result = HtmlToMarkdown.convert_string(html)
    trimmed = String.trim(result.markdown)
    assert trimmed =~ "1. First"
    assert trimmed =~ "2. Second"
  end

  test "convert tables" do
    html = """
    <table>
      <thead>
        <tr>
          <th>Header 1</th>
          <th>Header 2</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td>Row 1, Cell 1</td>
          <td>Row 1, Cell 2</td>
        </tr>
        <tr>
          <td>Row 2, Cell 1</td>
          <td>Row 2, Cell 2</td>
        </tr>
      </tbody>
    </table>

    <!-- Simple table -->
    <table>
      <tr><td>Simple 1</td><td>Simple 2</td></tr>
    </table>
    """

    result = HtmlToMarkdown.convert_string(html)

    expected_table1 =
      """
      | Header 1 | Header 2 |
      | --- | --- |
      | Row 1, Cell 1 | Row 1, Cell 2 |
      | Row 2, Cell 1 | Row 2, Cell 2 |
      """
      |> String.trim()

    expected_table2 =
      """
      | Simple 1 | Simple 2 |
      """
      |> String.trim()

    # Check for both tables, allowing for whitespace variations between them
    assert String.contains?(result.markdown, expected_table1)
    assert String.contains?(result.markdown, expected_table2)
  end

  test "convert definition lists" do
    html = """
    <dl>
      <dt>Term 1</dt>
      <dd>Definition 1</dd>
      <dt>Term 2</dt>
      <dd>Definition 2a</dd>
      <dd>Definition 2b</dd>
    </dl>
    """

    result = HtmlToMarkdown.convert_string(html)

    expected =
      """
      **Term 1**
      : Definition 1

      **Term 2**
      : Definition 2a

      : Definition 2b
      """
      |> String.trim()

    assert String.trim(result.markdown) == expected
  end

  test "convert code blocks" do
    html = """
    <pre><code>function test() {
      return 'test';
    }</code></pre>
    <p>Inline <code>code</code> test</p>
    """

    result = HtmlToMarkdown.convert_string(html)

    assert result.markdown =~ "```\nfunction test() {\n  return 'test';\n}\n```"
    assert result.markdown =~ "Inline `code` test"
  end

  test "convert blockquotes" do
    html = """
    <blockquote>
      <p>This is a quote</p>
      <p>With multiple paragraphs</p>
    </blockquote>
    """

    result = HtmlToMarkdown.convert_string(html)

    expected =
      """
      > This is a quote
      >
      > With multiple paragraphs
      """
      |> String.trim()

    assert String.trim(result.markdown) == expected
  end

  test "remove script and style tags" do
    html = """
    <h1>Title</h1>
    <script>
      alert('test');
    </script>
    <style>
      body { color: red; }
    </style>
    <p>Content</p>
    """

    result = HtmlToMarkdown.convert_string(html)

    assert result.markdown =~ "# Title"
    assert result.markdown =~ "Content"
    refute result.markdown =~ "alert('test')"
    refute result.markdown =~ "body { color: red; }"
  end

  test "extract title" do
    html = """
    <html>
      <head>
        <title>Page Title</title>
      </head>
      <body>
        <h1>Page Header</h1>
        <p>Content</p>
      </body>
    </html>
    """

    result = HtmlToMarkdown.convert_string(html)

    assert result.title == "Page Title"
    assert result.markdown =~ "# Page Header"
    assert result.markdown =~ "Content"
  end

  test "html_to_text utility function" do
    html = "<h1>Hello</h1><p>World</p>"
    text = HtmlToMarkdown.html_to_text(html)

    assert text == "# Hello\n\nWorld\n"
  end

  test "URL encoding" do
    html = """
    <a href="https://example.com/path with spaces">Link with spaces</a>
    """

    result = HtmlToMarkdown.convert_string(html)

    assert result.markdown =~ "[Link with spaces](https://example.com/path%20with%20spaces)"
  end

  test "fallback to og:title meta tag when title element is missing" do
    html = """
    <html>
      <head>
        <meta property="og:title" content="This help topic describes how to create a Port in the Megaport network.">
        <meta charset="utf-8">
      </head>
      <body>
        <h1>Creating a Port</h1>
        <p>Some content about creating ports.</p>
      </body>
    </html>
    """

    result = HtmlToMarkdown.convert_string(html)

    # Verify that it falls back to the og:title content
    assert result.title ==
             "This help topic describes how to create a Port in the Megaport network."

    assert result.markdown =~ "# Creating a Port"
    assert result.markdown =~ "Some content about creating ports."

    # Test when both title element and og:title meta tag are present (title should take precedence)
    html_with_both = """
    <html>
      <head>
        <title>Regular Title</title>
        <meta property="og:title" content="Open Graph Title">
      </head>
      <body>
        <h1>Content Heading</h1>
      </body>
    </html>
    """

    result_with_both = HtmlToMarkdown.convert_string(html_with_both)

    # The regular title should be used when both are present
    assert result_with_both.title == "Regular Title"
  end

  test "strip whitespace around link text" do
    html = """
    <ul>
      <li><a href=\"/pgvector/pgvector/pulls\"> Pull requests </a></li>
    </ul>
    """

    result = HtmlToMarkdown.convert_string(html)

    # Link text should be trimmed and formatted correctly
    assert String.trim(result.markdown) == "- [Pull requests](/pgvector/pgvector/pulls)"
  end

  test "preserve operator spacing in SQL code blocks" do
    html = """
    <pre><code>SELECT embedding <-> '[3,1,2]' AS distance FROM items;</code></pre>
    """

    result = HtmlToMarkdown.convert_string(html)

    expected =
      """
      ```
      SELECT embedding <-> '[3,1,2]' AS distance FROM items;
      ```
      """
      |> String.trim()

    assert result.markdown =~ expected
  end

  test "preserve indentation in code blocks" do
    html = """
    <pre><code>function example() {
        console.log('    indented');
    }</code></pre>
    """

    result = HtmlToMarkdown.convert_string(html)
    # The indented line should retain its leading spaces
    assert result.markdown =~ ~r/```
function example\(\) \{\n {4}console\.log\('    indented'\);\n\}\n```/
  end

  test "trim whitespace in headings" do
    html = """
      <h1 class="Overlay-title " id="custom-scopes-dialog-title">
        Saved searches
      </h1>
    """

    result = HtmlToMarkdown.convert_string(html)

    # Whitespace around heading text should be trimmed
    assert String.trim(result.markdown) == "# Saved searches"
  end

  test "convert highlighted SQL code blocks from docs" do
    html = ~S"""
    <p dir="auto">Create a new table with a vector column</p>
    <pre><code>CREATE TABLE items (id bigserial PRIMARY KEY, embedding vector(3));</code></pre>
    <p dir="auto">Or add a vector column to an existing table</p>
    <pre><code>ALTER TABLE items ADD COLUMN embedding vector(3);</code></pre>
    """

    result = HtmlToMarkdown.convert_string(html)
    markdown = String.trim(result.markdown)

    assert markdown =~ "Create a new table with a vector column"

    assert markdown =~
             "```\nCREATE TABLE items (id bigserial PRIMARY KEY, embedding vector(3));\n```"

    assert markdown =~ "Or add a vector column to an existing table"
    assert markdown =~ "```\nALTER TABLE items ADD COLUMN embedding vector(3);\n```"
  end

  test "convert this code block correctly" do
    html = """
    <pre><span class="pl-k">SELECT</span> <span class="pl-c1">AVG</span>(embedding) <span class="pl-k">FROM</span> items;</pre>
    """

    result = HtmlToMarkdown.convert_string(html)

    expected =
      """
      ```
      SELECT AVG(embedding) FROM items;
      ```
      """
      |> String.trim()

    assert result.markdown =~ expected
  end

  describe "div with pre edge case" do
    test "process div containing pre and text without error" do
      html = ~S"""
      <div>
        Intro text
        <pre><code>line1
      line2</code></pre>
        Outro text
      </div>
      """

      result = HtmlToMarkdown.convert_string(html)

      # Should include intro and outro text and code block
      assert result.markdown =~ "Intro text"
      assert result.markdown =~ "Outro text"
      assert result.markdown =~ "```
line1
line2
```"
    end
  end

  test "link text should not contain newlines" do
    html = """
    <p>
      <a href=\"https://example.com\">\nLine1\n\nLine2\n</a>
    </p>
    """

    result = HtmlToMarkdown.convert_string(html)
    assert String.trim(result.markdown) == "[Line1 Line2](https://example.com)"
  end

  test "should parse chunk of markdown from github correctly" do
    html = """
    <p dir="auto">or an Nx tensor with:</p>
    <div class="highlight highlight-source-elixir notranslate position-relative overflow-auto" dir="auto" data-snippet-clipboard-copy-content
    ="vector |&gt; Pgvector.to_tensor()"><pre><span class="pl-s1">vector</span> <span class="pl-c1">|&gt;</span> <span class="pl-v">Pgvector<
    /span><span class="pl-c1">.</span><span class="pl-en">to_tensor</span><span class="pl-kos">(</span><span class="pl-kos">)</span></pre></d
    iv>
    """

    result = HtmlToMarkdown.convert_string(html)

    # Check for the presence of the text and code block
    assert result.markdown ==
             ~S"""
             or an Nx tensor with:

             ```
             vector |> Pgvector.to_tensor()
             ```
             """
  end

  describe "highlighted code block handling" do
    test "uses raw snippet content when data-snippet-clipboard-copy-content is present" do
      html = ~S"""
      <div data-snippet-clipboard-copy-content="line1 &amp;&amp; line2">
        <pre><span>ignored</span></pre>
      </div>
      """

      result = HtmlToMarkdown.convert_string(html)

      expected =
        """
        ```
        line1 && line2
        ```
        """
        |> String.trim()

      assert String.trim(result.markdown) == expected
    end

    test "parses generic <pre> with spans when raw snippet attribute is absent" do
      html = ~S"""
      <pre><span>SELECT</span> <span>AVG</span>(value) FROM table;</pre>
      """

      result = HtmlToMarkdown.convert_string(html)

      expected =
        """
        ```
        SELECT AVG(value) FROM table;
        ```
        """
        |> String.trim()

      assert String.trim(result.markdown) == expected
    end
  end

  # tests for removing UI elements
  test "remove button elements" do
    html = "<button>Click me</button>"
    result = HtmlToMarkdown.convert_string(html)
    assert result.markdown == ""
  end

  test "remove form, input, and button elements" do
    html = """
    <form>
      <input type=\"text\" value=\"test\" />
      <button>Submit</button>
    </form>
    """

    result = HtmlToMarkdown.convert_string(html)
    assert result.markdown == ""
  end

  test "remove nav and footer elements" do
    html = """
    <nav>Navigation</nav>
    <footer>Footer info</footer>
    <p>Content</p>
    """

    result = HtmlToMarkdown.convert_string(html)
    assert result.markdown =~ "Content"
    refute result.markdown =~ "Navigation"
    refute result.markdown =~ "Footer info"
  end

  test "ensure formatting of p elements is correct" do
    html = """
    <div class="hide-sm hide-md">
    <h2 class="mb-3 h4">About</h2>

    <p class="f4 my-3">
       Open-source vector similarity search for Postgres
    </p>
    """

    result = HtmlToMarkdown.convert_string(html)

    expected =
      """
      ## About

      Open-source vector similarity search for Postgres
      """

    assert result.markdown == expected
  end

  # Tests for strip_whitespace_at_start_of_lines/1
  describe "strip_whitespace_at_start_of_lines/1" do
    test "removes leading whitespace from each line" do
      input = "  foo\n    bar\nbaz"
      expected = "foo\nbar\nbaz"
      assert HtmlToMarkdown.HtmlConverter.strip_whitespace_at_start_of_lines(input) == expected
    end

    test "returns empty string when input is empty" do
      assert HtmlToMarkdown.HtmlConverter.strip_whitespace_at_start_of_lines("") == ""
    end

    test "does nothing to lines without leading whitespace" do
      input = "foo\nbar\nbaz"
      assert HtmlToMarkdown.HtmlConverter.strip_whitespace_at_start_of_lines(input) == input
    end

    test "handles lines with only whitespace" do
      input = "  \n    \n"
      expected = "\n\n"
      assert HtmlToMarkdown.HtmlConverter.strip_whitespace_at_start_of_lines(input) == expected
    end

    test "does not strip whitespace within fenced code blocks" do
      input = """
      foo
      ```elixir
          bar
        baz
      ```
        qux
      """

      expected = """
      foo
      ```elixir
          bar
        baz
      ```
      qux
      """

      assert HtmlToMarkdown.HtmlConverter.strip_whitespace_at_start_of_lines(input) == expected
    end

    test "handles weird code blocks" do
      input = """
      <div class="highlight"><pre><span></span><code tabindex="0"><a id="__codelineno-1-1" name="__codelineno-1-1" href="#__codelineno-1-1"></a><span class="err">#</span><span class="w"> </span><span class="err">HELP</span><span class="w"> </span><span class="err">megapor</span><span class="kc">t</span><span class="err">_service_i</span><span class="kc">n</span><span class="err">pu</span><span class="kc">t</span><span class="err">_errors_</span><span class="kc">t</span><span class="err">o</span><span class="kc">tal</span><span class="w"> </span><span class="err">The</span><span class="w"> </span><span class="kc">t</span><span class="err">o</span><span class="kc">tal</span><span class="w"> </span><span class="kc">nu</span><span class="err">mber</span><span class="w"> </span><span class="err">o</span><span class="kc">f</span><span class="w"> </span><span class="err">i</span><span class="kc">n</span><span class="err">pu</span><span class="kc">t</span><span class="w"> </span><span class="err">errors.</span>
      <a id="__codelineno-1-2" name="__codelineno-1-2" href="#__codelineno-1-2"></a><span class="err">#</span><span class="w"> </span><span class="err">TYPE</span><span class="w"> </span><span class="err">megapor</span><span class="kc">t</span><span class="err">_service_i</span><span class="kc">n</span><span class="err">pu</span><span class="kc">t</span><span class="err">_errors_</span><span class="kc">t</span><span class="err">o</span><span class="kc">tal</span><span class="w"> </span><span class="err">cou</span><span class="kc">nter</span>
      <a id="__codelineno-1-3" name="__codelineno-1-3" href="#__codelineno-1-3"></a><span class="err">#</span><span class="w"> </span><span class="err">HELP</span><span class="w"> </span><span class="err">megapor</span><span class="kc">t</span><span class="err">_service_op</span><span class="kc">t</span><span class="err">ical_receive_power_dbm</span><span class="w"> </span><span class="err">Op</span><span class="kc">t</span><span class="err">ical</span><span class="w"> </span><span class="err">receive</span><span class="w"> </span><span class="err">power</span><span class="w"> </span><span class="err">level</span><span class="w"> </span><span class="err">i</span><span class="kc">n</span><span class="w"> </span><span class="err">dBm.</span>
      <a id="__codelineno-1-4" name="__codelineno-1-4" href="#__codelineno-1-4"></a><span class="err">#</span><span class="w"> </span><span class="err">TYPE</span><span class="w"> </span><span class="err">megapor</span><span class="kc">t</span><span class="err">_service_op</span><span class="kc">t</span><span class="err">ical_receive_power_dbm</span><span class="w"> </span><span class="err">gauge</span>
      <a id="__codelineno-1-5" name="__codelineno-1-5" href="#__codelineno-1-5"></a><span class="err">#</span><span class="w"> </span><span class="err">HELP</span><span class="w"> </span><span class="err">megapor</span><span class="kc">t</span><span class="err">_service_op</span><span class="kc">t</span><span class="err">ical_</span><span class="kc">trans</span><span class="err">mi</span><span class="kc">t</span><span class="err">_power_dbm</span><span class="w"> </span><span class="err">Op</span><span class="kc">t</span><span class="err">ical</span><span class="w"> </span><span class="kc">trans</span><span class="err">mi</span><span class="kc">t</span><span class="w"> </span><span class="err">power</span><span class="w"> </span><span class="err">level</span><span class="w"> </span><span class="err">i</span><span class="kc">n</span><span class="w"> </span><span class="err">dBm.</span>
      <a id="__codelineno-1-6" name="__codelineno-1-6" href="#__codelineno-1-6"></a><span class="err">#</span><span class="w"> </span><span class="err">TYPE</span><span class="w"> </span><span class="err">megapor</span><span class="kc">t</span><span class="err">_service_op</span><span class="kc">t</span><span class="err">ical_</span><span class="kc">trans</span><span class="err">mi</span><span class="kc">t</span><span class="err">_power_dbm</span><span class="w"> </span><span class="err">gauge</span>
      <a id="__codelineno-1-7" name="__codelineno-1-7" href="#__codelineno-1-7"></a><span class="err">#</span><span class="w"> </span><span class="err">HELP</span><span class="w"> </span><span class="err">megapor</span><span class="kc">t</span><span class="err">_service_ou</span><span class="kc">t</span><span class="err">pu</span><span class="kc">t</span><span class="err">_errors_</span><span class="kc">t</span><span class="err">o</span><span class="kc">tal</span><span class="w"> </span><span class="err">The</span><span class="w"> </span><span class="kc">t</span><span class="err">o</span><span class="kc">tal</span><span class="w"> </span><span class="kc">nu</span><span class="err">mber</span><span class="w"> </span><span class="err">o</span><span class="kc">f</span><span class="w"> </span><span class="err">ou</span><span class="kc">t</span><span class="err">pu</span><span class="kc">t</span><span class="w"> </span><span class="err">errors.</span>
      <a id="__codelineno-1-8" name="__codelineno-1-8" href="#__codelineno-1-8"></a><span class="err">#</span><span class="w"> </span><span class="err">TYPE</span><span class="w"> </span><span class="err">megapor</span><span class="kc">t</span><span class="err">_service_ou</span><span class="kc">t</span><span class="err">pu</span><span class="kc">t</span><span class="err">_errors_</span><span class="kc">t</span><span class="err">o</span><span class="kc">tal</span><span class="w"> </span><span class="err">cou</span><span class="kc">nter</span>
      <a id="__codelineno-1-9" name="__codelineno-1-9" href="#__codelineno-1-9"></a><span class="err">#</span><span class="w"> </span><span class="err">HELP</span><span class="w"> </span><span class="err">megapor</span><span class="kc">t</span><span class="err">_service_receive_by</span><span class="kc">tes</span><span class="err">_</span><span class="kc">t</span><span class="err">o</span><span class="kc">tal</span><span class="w"> </span><span class="err">The</span><span class="w"> </span><span class="kc">t</span><span class="err">o</span><span class="kc">tal</span><span class="w"> </span><span class="kc">nu</span><span class="err">mber</span><span class="w"> </span><span class="err">o</span><span class="kc">f</span><span class="w"> </span><span class="err">by</span><span class="kc">tes</span><span class="w"> </span><span class="err">received.</span>
      <a id="__codelineno-1-10" name="__codelineno-1-10" href="#__codelineno-1-10"></a><span class="err">#</span><span class="w"> </span><span class="err">TYPE</span><span class="w"> </span><span class="err">megapor</span><span class="kc">t</span><span class="err">_service_receive_by</span><span class="kc">tes</span><span class="err">_</span><span class="kc">t</span><span class="err">o</span><span class="kc">tal</span><span class="w"> </span><span class="err">cou</span><span class="kc">nter</span>
      <a id="__codelineno-1-11" name="__codelineno-1-11" href="#__codelineno-1-11"></a><span class="err">#</span><span class="w"> </span><span class="err">HELP</span><span class="w"> </span><span class="err">megapor</span><span class="kc">t</span><span class="err">_service_receive_packe</span><span class="kc">ts</span><span class="err">_</span><span class="kc">t</span><span class="err">o</span><span class="kc">tal</span><span class="w"> </span><span class="err">The</span><span class="w"> </span><span class="kc">t</span><span class="err">o</span><span class="kc">tal</span><span class="w"> </span><span class="kc">nu</span><span class="err">mber</span><span class="w"> </span><span class="err">o</span><span class="kc">f</span><span class="w"> </span><span class="err">packe</span><span class="kc">ts</span><span class="w"> </span><span class="err">received.</span>
      <a id="__codelineno-1-12" name="__codelineno-1-12" href="#__codelineno-1-12"></a><span class="err">#</span><span class="w"> </span><span class="err">TYPE</span><span class="w"> </span><span class="err">megapor</span><span class="kc">t</span><span class="err">_service_receive_packe</span><span class="kc">ts</span><span class="err">_</span><span class="kc">t</span><span class="err">o</span><span class="kc">tal</span><span class="w"> </span><span class="err">cou</span><span class="kc">nter</span>
      <a id="__codelineno-1-13" name="__codelineno-1-13" href="#__codelineno-1-13"></a><span class="err">#</span><span class="w"> </span><span class="err">HELP</span><span class="w"> </span><span class="err">megapor</span><span class="kc">t</span><span class="err">_service_</span><span class="kc">trans</span><span class="err">mi</span><span class="kc">t</span><span class="err">_by</span><span class="kc">tes</span><span class="err">_</span><span class="kc">t</span><span class="err">o</span><span class="kc">tal</span><span class="w"> </span><span class="err">The</span><span class="w"> </span><span class="kc">t</span><span class="err">o</span><span class="kc">tal</span><span class="w"> </span><span class="kc">nu</span><span class="err">mber</span><span class="w"> </span><span class="err">o</span><span class="kc">f</span><span class="w"> </span><span class="err">by</span><span class="kc">tes</span><span class="w"> </span><span class="kc">trans</span><span class="err">mi</span><span class="kc">tte</span><span class="err">d.</span>
      <a id="__codelineno-1-14" name="__codelineno-1-14" href="#__codelineno-1-14"></a><span class="err">#</span><span class="w"> </span><span class="err">TYPE</span><span class="w"> </span><span class="err">megapor</span><span class="kc">t</span><span class="err">_service_</span><span class="kc">trans</span><span class="err">mi</span><span class="kc">t</span><span class="err">_by</span><span class="kc">tes</span><span class="err">_</span><span class="kc">t</span><span class="err">o</span><span class="kc">tal</span><span class="w"> </span><span class="err">cou</span><span class="kc">nter</span>
      <a id="__codelineno-1-15" name="__codelineno-1-15" href="#__codelineno-1-15"></a><span class="err">#</span><span class="w"> </span><span class="err">HELP</span><span class="w"> </span><span class="err">megapor</span><span class="kc">t</span><span class="err">_service_</span><span class="kc">trans</span><span class="err">mi</span><span class="kc">t</span><span class="err">_packe</span><span class="kc">ts</span><span class="err">_</span><span class="kc">t</span><span class="err">o</span><span class="kc">tal</span><span class="w"> </span><span class="err">The</span><span class="w"> </span><span class="kc">t</span><span class="err">o</span><span class="kc">tal</span><span class="w"> </span><span class="kc">nu</span><span class="err">mber</span><span class="w"> </span><span class="err">o</span><span class="kc">f</span><span class="w"> </span><span class="err">packe</span><span class="kc">ts</span><span class="w"> </span><span class="kc">trans</span><span class="err">mi</span><span class="kc">tte</span><span class="err">d.</span>
      <a id="__codelineno-1-16" name="__codelineno-1-16" href="#__codelineno-1-16"></a><span class="err">#</span><span class="w"> </span><span class="err">TYPE</span><span class="w"> </span><span class="err">megapor</span><span class="kc">t</span><span class="err">_service_</span><span class="kc">trans</span><span class="err">mi</span><span class="kc">t</span><span class="err">_packe</span><span class="kc">ts</span><span class="err">_</span><span class="kc">t</span><span class="err">o</span><span class="kc">tal</span><span class="w"> </span><span class="err">cou</span><span class="kc">nter</span>
      <a id="__codelineno-1-17" name="__codelineno-1-17" href="#__codelineno-1-17"></a><span class="err">#</span><span class="w"> </span><span class="err">HELP</span><span class="w"> </span><span class="err">megapor</span><span class="kc">t</span><span class="err">_service_up</span><span class="w"> </span><span class="err">Opera</span><span class="kc">t</span><span class="err">io</span><span class="kc">nal</span><span class="w"> </span><span class="err">s</span><span class="kc">tatus</span><span class="w"> </span><span class="err">o</span><span class="kc">f</span><span class="w"> </span><span class="kc">t</span><span class="err">he</span><span class="w"> </span><span class="err">service.</span>
      <a id="__codelineno-1-18" name="__codelineno-1-18" href="#__codelineno-1-18"></a><span class="err">#</span><span class="w"> </span><span class="err">TYPE</span><span class="w"> </span><span class="err">megapor</span><span class="kc">t</span><span class="err">_service_up</span><span class="w"> </span><span class="err">gauge</span>
      </code></pre></div>
      """

      expected = """
      ```
      # HELP megaport_service_input_errors_total The total number of input errors.
      # TYPE megaport_service_input_errors_total counter
      # HELP megaport_service_optical_receive_power_dbm Optical receive power level in dBm.
      # TYPE megaport_service_optical_receive_power_dbm gauge
      # HELP megaport_service_optical_transmit_power_dbm Optical transmit power level in dBm.
      # TYPE megaport_service_optical_transmit_power_dbm gauge
      # HELP megaport_service_output_errors_total The total number of output errors.
      # TYPE megaport_service_output_errors_total counter
      # HELP megaport_service_receive_bytes_total The total number of bytes received.
      # TYPE megaport_service_receive_bytes_total counter
      # HELP megaport_service_receive_packets_total The total number of packets received.
      # TYPE megaport_service_receive_packets_total counter
      # HELP megaport_service_transmit_bytes_total The total number of bytes transmitted.
      # TYPE megaport_service_transmit_bytes_total counter
      # HELP megaport_service_transmit_packets_total The total number of packets transmitted.
      # TYPE megaport_service_transmit_packets_total counter
      # HELP megaport_service_up Operational status of the service.
      # TYPE megaport_service_up gauge
      ```
      """

      %{markdown: result} = HtmlToMarkdown.convert_string(input)
      assert result == expected
    end
  end

  test "convert table with whitespace nodes" do
    html = "<table><tr>\n<th>H1</th>\n<th>H2</th>\n</tr></table>"
    result = HtmlToMarkdown.convert_string(html)
    assert result.markdown =~ "| H1 | H2 |"
  end
end
