defmodule ConduitSQS.Mixfile do
  use Mix.Project

  def project do
    [
      app: :conduit_sqs,
      version: "0.1.0",
      elixir: "~> 1.4",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),

      # Docs
      name: "ConduitSQS",
      source_url: "https://github.com/conduitframework/conduit_sqs",
      homepage_url: "https://hexdocs.pm/conduit_sqs",
      docs: docs(),

      # Package
      description: "Amazon SQS adapter for Conduit.",
      package: package(),

      dialyzer: [flags: ["-Werror_handling", "-Wrace_conditions"]],

      # Coveralls
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: ["coveralls": :test, "coveralls.circle": :test],

      aliases: ["publish": ["hex.publish", &git_tag/1]]
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:conduit, "~> 0.8"},
     {:injex, "~> 1.0"},
     {:ex_doc, "~> 0.14", only: :dev},
     {:dialyxir, "~> 0.4", only: :dev},
     {:excoveralls, "~> 0.5", only: :test}]
  end

  defp package do
    [# These are the default files included in the package
     name: :conduit_sqs,
     files: ["lib", "mix.exs", "README*", "LICENSE*"],
     maintainers: ["Allen Madsen"],
     licenses: ["Apache 2.0"],
     links: %{"GitHub" => "https://github.com/conduitframework/conduit_sqs",
              "Docs" => "https://hexdocs.pm/conduit_sqs"}]
  end

  defp docs do
    [main: "readme",
     project: "ConduitSQS",
     extra_section: "Guides",
     extras: ["README.md"],
     assets: ["assets"]]
  end

  defp git_tag(_args) do
    tag = "v" <> Mix.Project.config[:version]
    System.cmd("git", ["tag", tag])
    System.cmd("git", ["push", "origin", tag])
  end
end
