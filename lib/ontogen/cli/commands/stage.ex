defmodule Ontogen.CLI.Commands.Stage do
  alias Ontogen.CLI.{Stage, Action}

  @file_opt_spec [
    value_name: "STAGE_FILE",
    help: "Stage file with a RDF dataset of the changes",
    required: false,
    default: &Stage.default_file/0,
    parser: :string
  ]
  def file_opt_spec, do: Keyword.put(@file_opt_spec, :long, "--stage")

  use Ontogen.CLI.Command,
    name: :stage,
    about: "Stage various change actions for a commit",
    args: [
      stage: @file_opt_spec
    ],
    options:
      Action.command_opt_spec() ++
        Action.speech_act_opt_spec()

  @impl true
  def handle_call(args, options, _flags, []) do
    Stage.stage(options, Map.merge(options, args))
  end
end
