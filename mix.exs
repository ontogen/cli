defmodule Ontogen.CLI.MixProject do
  use Mix.Project

  @scm_url "https://github.com/ontogen/cli"

  @version File.read!("VERSION") |> String.trim()

  def project do
    [
      app: :ontogen_cli,
      version: @version,
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      aliases: aliases(),
      releases: releases(),
      escript: [
        main_module: Ontogen.CLI,
        name: "og"
      ],
      preferred_cli_env: [
        check: :test,
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      test_coverage: [tool: ExCoveralls],

      # Docs
      name: "Ontogen CLI",
      docs: docs()
    ]
  end

  def releases do
    [
      og: [
        steps: [:assemble, &Burrito.wrap/1],
        burrito: [
          targets: [
            macos_silicon: [os: :darwin, cpu: :aarch64],
            macos: [os: :darwin, cpu: :x86_64],
            linux: [os: :linux, cpu: :x86_64],
            windows: [os: :windows, cpu: :x86_64]
          ]
        ]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Ontogen.CLI, []}
    ]
  end

  defp deps do
    [
      ontogen_dep(:ontogen, "~> 0.1"),
      rdf_ex_dep(:rdf, "~> 2.0"),
      rdf_ex_dep(:json_ld, ">= 0.3.9"),
      rdf_ex_dep(:rdf_xml, "~> 1.2"),
      rdf_ex_dep(:prov, "~> 0.1"),
      {:optimus, "~> 0.5"},
      {:burrito, "~> 1.1"},
      {:hackney, "~> 1.17"},
      {:ex_doc, "~> 0.34", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18", only: :test},
      # This dependency is needed for ExCoveralls when OTP < 25
      {:castore, "~> 1.0"}
    ]
  end

  defp ontogen_dep(dep, version) do
    case System.get_env("ONTOGEN_PACKAGES_SRC") do
      "LOCAL" -> {dep, path: "../#{dep}"}
      _ -> {dep, version}
    end
  end

  defp rdf_ex_dep(dep, version) do
    case System.get_env("RDF_EX_PACKAGES_SRC") do
      "LOCAL" -> {dep, path: "../../../RDF.ex/src/#{dep}"}
      _ -> {dep, version}
    end
  end

  defp docs do
    [
      main: "Ontogen.CLI",
      source_url: @scm_url,
      source_ref: "v#{@version}",
      logo: "logo.png",
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"],
      extras: [
        {:"README.md", [title: "About"]},
        {:"CHANGELOG.md", [title: "CHANGELOG"]},
        {:"LICENSE.md", [title: "License"]}
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp aliases do
    [
      check: [
        "clean",
        "deps.unlock --check-unused",
        "compile --warnings-as-errors",
        "format --check-formatted",
        "test --warnings-as-errors"
      ]
    ]
  end
end
