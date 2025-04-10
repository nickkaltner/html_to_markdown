defmodule HtmlToMarkdownPerformanceTest do
  use ExUnit.Case

  test "measure conversion time for a HTML string" do
    html = """
    <!doctype html>
    <html lang="en" class="no-js">
    <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <link rel="icon" href="/images/favicon.ico">
    <meta name="generator" content="mkdocs-1.6.0, mkdocs-material-9.5.20">
    <title>Creating a Port - Megaport Documentation</title>
    </head>
    <body dir="ltr">
    <div class="md-container" data-md-component="container">
      <main class="md-main" data-md-component="main">
        <div class="md-content" data-md-component="content">
          <h1 id="creating-a-port">Creating a Port</h1>
          <p>This topic describes how to create a <span class="tooltip">Port<span class="tooltiptext"></p><p>A Port is the high-speed Ethernet interface that connects to Megaport's global software-defined network (SDN). Ports are available in 1 Gbps, 10 Gbps and 100 Gbps speed options.<br></span></span> in the Megaport network. Your organization's Port is the physical point of connection between your organization's network and the Megaport network. You will need to deploy a Port wherever you want to direct traffic.</p>
          <p>The Megaport Portal steps you through selecting a data center location, specifying the Port details, and placing the order. To connect, you can start with a single data center location; however, we recommend selecting two different locations to provide redundancy.</p>
          <div class="admonition note">
          <p class="admonition-title">Note</p>
          <p>Before proceeding, ensure that you have set up your Megaport Portal account. For more information, see <a href="../../setting-up/">Setting Up a Megaport Account</a>.</p>
          </div>
          <p><strong>To create a new Port</strong></p>
          <ol>
          <li>In the <a href="https://portal.megaport.com" target="_blank">Megaport Portal</a>, go to the <strong>Services</strong> page.</li>
          <li>Click <strong>Create Port</strong>.<br />
          <img alt="Create Port" class="shadow" src="../img/create_port_button.png" width="250px" />  </li>
          <li>
          <p>Select your preferred data center location and click <strong>Next</strong>.<br />
          You can use the <strong>Search</strong> field to find the Port name, Country, Metro City, or address of your destination Port.</p>
          </li>
          </ol>
        </div>
      </main>
    </div>
    </body>
    </html>
    """

    # Measure the time it takes to convert the HTML to Markdown
    {time, result} =
      :timer.tc(fn ->
        HtmlToMarkdown.convert_string(html)
      end)

    # Convert microseconds to milliseconds for better readability
    time_ms = time / 1000

    # Output the conversion time and the result
    IO.puts("-----------------------------------------------")
    IO.puts("HTML to markdown for title: #{result.title}")
    IO.puts("-----------------------------------------------")
    IO.puts("First 500 characters of markdown: \n#{String.slice(result.markdown, 0, 500)}")
    IO.puts("-----------------------------------------------")
    IO.puts("HTML to Markdown conversion from a string took #{time_ms} milliseconds")

    # Basic assertion to make sure we get some markdown output
    assert result.markdown != nil
    assert String.contains?(result.markdown, "Creating a Port")
  end

  test "measure conversion time for external HTML file" do
    # Create a temporary file path
    temp_file = Path.join(System.tmp_dir!(), "megaport_test.html")

    # Write the HTML content to the temporary file
    File.write!(temp_file, File.read!("test/samples/megaport.html"))

    # Measure time
    {time, result_tuple} = :timer.tc(HtmlToMarkdown, :convert_file, [temp_file])
    # Destructure the tuple
    {:ok, result} = result_tuple

    # Assertions (optional, focus is on timing)
    assert is_binary(result.markdown)
    assert is_binary(result.title)

    # Output results
    IO.puts("-" <> String.duplicate("-", 70))
    IO.puts("HTML to markdown for title: #{result.title}")
    IO.puts("-" <> String.duplicate("-", 70))
    IO.puts("First 500 characters of markdown: ")
    IO.puts(String.slice(result.markdown, 0, 500))
    IO.puts("-" <> String.duplicate("-", 70))
    IO.puts("HTML to Markdown conversion from file took #{time / 1000} milliseconds")

    # Clean up temporary file
    File.rm(temp_file)

    # Basic assertion to make sure we get some markdown output
    assert result.markdown != nil
    assert String.contains?(result.markdown, "Creating a Port")
  end

  test "verify title extraction in DocumentConverterResult" do
    html = """
    <!doctype html>
    <html lang="en">
    <head>
      <title>Test Document Title</title>
      <meta charset="utf-8">
    </head>
    <body>
      <h1>Main Content Heading</h1>
      <p>Some paragraph text.</p>
    </body>
    </html>
    """

    result = HtmlToMarkdown.convert_string(html)

    # Verify the title was correctly extracted
    assert result.title == "Test Document Title"

    # Also verify the title and content are correctly processed
    assert is_struct(result, HtmlToMarkdown.DocumentConverterResult)
    assert result.markdown =~ "# Main Content Heading"
    assert result.markdown =~ "Some paragraph text."

    # Test with no title tag
    html_no_title = """
    <!doctype html>
    <html lang="en">
    <head>
      <meta charset="utf-8">
    </head>
    <body>
      <h1>Document With No Title Tag</h1>
      <p>Some content.</p>
    </body>
    </html>
    """

    result_no_title = HtmlToMarkdown.convert_string(html_no_title)

    # When no title tag exists, title should be nil
    assert result_no_title.title == nil
    assert result_no_title.markdown =~ "# Document With No Title Tag"
  end
end
