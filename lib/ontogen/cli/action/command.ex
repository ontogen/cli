defmodule Ontogen.CLI.Action.Command do
  @doc """
  `Ontogen.CLI.Command` generator for the staging action commands.
  """

  alias Ontogen.CLI.{Stage, Action}

  @command_spec [
    args: [
      file: [
        value_name: "FILE(S)",
        help:
          "RDF files with data to be staged. Note: Order matters regarding overlaps - last one wins.",
        required: true,
        parser: :string
      ]
    ],
    options:
      Action.speech_act_opt_spec() ++
        [
          stage: Ontogen.CLI.Commands.Stage.file_opt_spec()
        ],
    allow_unknown_args: true
  ]

  defmacro __using__(command_spec) do
    action = Keyword.fetch!(command_spec, :name)
    command_spec = Keyword.merge(@command_spec, command_spec)

    quote do
      use Ontogen.CLI.Command, unquote(Macro.escape(command_spec))

      def handle_call(%{file: file}, options, _flags, files) do
        Stage.stage([{unquote(action), [file | files]}], options)
      end
    end
  end
end
