defmodule Ontogen.CLI do
  @moduledoc """
  The command line interface of `Ontogen`.
  """

  import Ontogen.CLI.Helper

  @commands [
    Ontogen.CLI.Commands.Init,
    Ontogen.CLI.Commands.Add,
    Ontogen.CLI.Commands.Remove,
    Ontogen.CLI.Commands.Update,
    Ontogen.CLI.Commands.Replace,
    Ontogen.CLI.Commands.Stage,
    Ontogen.CLI.Commands.Commit,
    Ontogen.CLI.Commands.Log
  ]

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

  if Application.compile_env(:ontogen_cli, :in_burrito) do
    def start(_type, _args) do
      Burrito.Util.Args.get_arguments()
      |> main()
      |> System.halt()
    end
  else
    def start(_, _) do
      {:ok, self()}
    end
  end

  def main(args) do
    @opt_parser_spec
    |> Optimus.new!()
    |> Optimus.parse!(args)
    |> call_command()
    |> handle_result()
  end

  defp call_command(
         {[command],
          %Optimus.ParseResult{args: args, options: options, flags: flags, unknown: unknown}}
       ) do
    apply(@command_map[command], :call, [args, options, flags, unknown])
  rescue
    exception -> {:error, exception}
  end

  defp handle_result(:ok), do: 0
  defp handle_result({:ok, code}) when is_integer(code), do: code
  defp handle_result({:error, error}), do: error_result(error)
  defp handle_result(:abort), do: :abort
end
