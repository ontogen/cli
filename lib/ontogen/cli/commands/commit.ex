defmodule Ontogen.CLI.Commands.Commit do
  alias Ontogen.CLI.{Action, Stage, Helper}
  alias RDF.XSD

  use Ontogen.CLI.Command,
    name: :commit,
    about: "Add data to the repository in the store and record the changes",
    args: [
      stage: Ontogen.CLI.Commands.Stage.file_opt_spec()
    ],
    options:
      Action.command_opt_spec() ++
        Action.speech_act_opt_spec() ++
        [
          message: [
            short: "-m",
            long: "--message",
            value_name: "STRING",
            help: "Commit message",
            required: true,
            parser: :string
          ],
          committed_at: [
            long: "--committed-at",
            value_name: "DATE_TIME",
            help: "Time of committing the data",
            required: false,
            default: &XSD.DateTime.now/0,
            parser: &Helper.valid_xsd_datetime/1
          ],
          committed_by: [
            long: "--committed-by",
            value_name: "URI",
            help: "Creator of the commit",
            required: false,
            parser: :string
          ]
        ],
    flags: []

  @impl true
  def call(%{stage: file}, options, _flags, []) do
    stage_file = file || Stage.default_file()

    with :ok <- stage(stage_file, options) do
      commit(stage_file, options)
    end
  end

  defp stage(stage_file, changes_and_options) do
    if Action.options?(changes_and_options) do
      Stage.stage(stage_file, changes_and_options, changes_and_options)
    else
      :ok
    end
  end

  defp commit(stage_file, options) do
    with {:ok, speech_act, metadata} <- Stage.speech_act(stage_file),
         {:ok, commit} <-
           Ontogen.commit(
             speech_act: speech_act,
             message: options[:message],
             time: XSD.DateTime.value(options[:committed_at]),
             committer: RDF.iri(options[:committed_by] || Helper.user_iri()),
             additional_prov_metadata: metadata
           ) do
      Stage.reset(stage_file)
      success(Helper.commit_info(commit))
    end
  end
end
