defmodule Ontogen.CLI.Commit do
  alias Ontogen.CLI.{Action, Stage, Helper}
  alias RDF.XSD

  use Ontogen.CLI.Command,
    name: :commit,
    about: "Add data to the repository in the store and record the changes",
    args: [
      stage: Stage.file_opt_spec()
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

  import Ontogen.IdUtils, only: [to_hash: 1]

  @impl true
  def call(%{stage: file}, options, flags, []) do
    stage_file = file || Stage.default_file()

    with :ok <- stage(stage_file, options, flags) do
      commit(stage_file, options)
    end
  end

  defp stage(stage_file, options, flags) do
    if Action.options?(options) do
      Stage.stage(options, Map.put(options, :stage, stage_file), flags)
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
      success(commit_info(commit))
    end
  end

  defp commit_info(commit) do
    [first_line | _] = String.split(commit.message, "\n", parts: 2)
    root_commit = unless commit.parent, do: "(root-commit) "

    insertions_count =
      ((commit.add && RTC.Compound.triple_count(commit.add.statements)) || 0) +
        ((commit.update && RTC.Compound.triple_count(commit.update.statements)) || 0) +
        ((commit.replace && RTC.Compound.triple_count(commit.replace.statements)) || 0)

    deletions_count = (commit.remove && RTC.Compound.triple_count(commit.remove.statements)) || 0

    overwrites_count =
      (commit.overwrite && RTC.Compound.triple_count(commit.overwrite.statements)) || 0

    """
    [#{root_commit}#{to_hash(commit)}] #{first_line}
     #{insertions_count} insertions, #{deletions_count} deletions, #{overwrites_count} overwrites
    """
  end
end
