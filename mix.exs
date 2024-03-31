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
      {:optimus, "~> 0.5"},
      {:owl, "~> 0.9"},
      {:burrito, "~> 1.0"}
    ]
  end
end
