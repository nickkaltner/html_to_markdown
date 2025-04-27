defmodule HtmlToMarkdown.MixProject do
  use Mix.Project

  def project do
    [
      app: :html_to_markdown,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      # Documentation settings
      name: "HtmlToMarkdown",
      source_url: "https://github.com/nickkaltner/html_to_markdown",
      homepage_url: "https://github.com/nickkaltner/html_to_markdown",
      docs: &docs/0
    ]
  end

  defp docs do
    [
      main: "HtmlToMarkdown",
      # , "CHANGELOG.md"
      extras: ["README.md"],
      groups_for_modules: [
        "HTML to Markdown": [
          HtmlToMarkdown,
          HtmlToMarkdown.HtmlConverter,
          HtmlToMarkdown.MarkdownConverter
        ]
      ],
      formatters: ["html"]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # For HTML parsing, similar to BeautifulSoup
      {:floki, "~> 0.37.1"},
      # For handling HTML entities
      {:html_entities, "~> 0.5"},
      # For URL parsing and manipulation
      {:uri_query, "~> 0.2.0"},
      # For documentation
      {:ex_doc, "~> 0.29", only: :dev, runtime: false},
      # For static code analysis
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      # For static type checking
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end
end
