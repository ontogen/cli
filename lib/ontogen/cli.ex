defmodule Ontogen.CLI do
  @moduledoc """
  The command line interface of `Ontogen`.
  """

  import Ontogen.CLI.Helper

  @commands []

  @command_map Map.new(@commands, &{&1.name(), &1})

  @opt_parser_spec [
    name: "ontogen",
    description: "Ontogen CLI",
    version: File.read!("VERSION"),
    author: "Marcel Otto",
    about: "CLI of the Ontogen version control system for RDF datasets",
    allow_unknown_args: false,
    parse_double_dash: true,
    subcommands: Keyword.new(@commands, &{&1.name(), &1.command_spec()})
  ]

  def opt_parser_spec, do: @opt_parser_spec

  def main(args) do
    @opt_parser_spec
    |> Optimus.new!()
    |> Optimus.parse!(args)
    |> call_command()
    |> handle_result()
  end

  defp call_command({[command], %Optimus.ParseResult{args: args, options: options, flags: flags}}) do
    apply(@command_map[command], :call, [args, options, flags])
  rescue
    exception -> {:error, exception}
  end

  defp handle_result(:ok), do: 0
  defp handle_result({:ok, code}) when is_integer(code), do: code
  defp handle_result({:error, error}), do: error_result(error)
  defp handle_result(:abort), do: :abort
end
