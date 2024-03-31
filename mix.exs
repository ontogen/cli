defmodule Ontogen.CLI.MixProject do
  use Mix.Project

  @version File.read!("VERSION") |> String.trim()

  def project do
    [
      app: :ontogen_cli,
      version: @version,
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      releases: releases(),
      escript: [
        main_module: Ontogen.CLI,
        name: "og"
      ]
    ]
  end

  def releases do
    [
      ontogen_cli: [
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
      {:optimus, "~> 0.5"},
      {:owl, "~> 0.9"},
      {:burrito, "~> 1.0"},
      {:hackney, "~> 1.17"},
      {:briefly, "~> 0.5", only: :test}
    ]
  end

  defp ontogen_dep(dep, version) do
    case System.get_env("ONTOGEN_PACKAGES_SRC") do
      "LOCAL" -> {dep, path: "../#{dep}"}
      _ -> {dep, version}
    end
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
