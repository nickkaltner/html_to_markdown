defmodule HtmlToMarkdown.DocumentConverterResult do
  @moduledoc """
  Contains the converted Markdown text and optional metadata like title.
  Equivalent to DocumentConverterResult in the Python implementation.
  """

  defstruct [:markdown, :title]

  @type t :: %__MODULE__{
          markdown: String.t(),
          title: String.t() | nil
        }
end

defmodule HtmlToMarkdown.StreamInfo do
  @moduledoc """
  A struct that holds metadata about the stream being converted.
  Equivalent to StreamInfo in the Python implementation.
  """

  defstruct [:mimetype, :extension, :charset, :url]

  @type t :: %__MODULE__{
          mimetype: String.t() | nil,
          extension: String.t() | nil,
          charset: String.t() | nil,
          url: String.t() | nil
        }
end

defmodule HtmlToMarkdown.DocumentConverter do
  @moduledoc """
  Behavior that defines the interface for document converters.
  Equivalent to DocumentConverter in the Python implementation.
  """

  alias HtmlToMarkdown.{DocumentConverterResult, StreamInfo}

  @callback accepts(
              file_stream :: File.io_device(),
              stream_info :: StreamInfo.t(),
              opts :: keyword()
            ) :: boolean()

  @callback convert(
              file_stream :: File.io_device(),
              stream_info :: StreamInfo.t(),
              opts :: keyword()
            ) :: DocumentConverterResult.t()
end
