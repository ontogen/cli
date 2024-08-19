defmodule Ontogen.CLI.Commands.Revert do
  alias Ontogen.CLI.Helper
  alias Ontogen.Commit
  alias RDF.XSD

  use Ontogen.CLI.Command,
    name: :revert,
    about: "Revert some existing commits",
    args: [
      range: [
        value_name: "COMMIT_RANGE",
        help: "Range of commits to revert",
        required: true,
        parser: :string
      ]
    ],
    options: [
      message: [
        short: "-m",
        long: "--message",
        value_name: "STRING",
        help: "Commit message",
        required: false,
        parser: :string
      ],
      # TODO: extract these shared options?
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
  def handle_call(%{range: spec}, options, _flags, []) do
    with {:ok, range} <- Commit.Range.parse(spec, single_ref_as: :single_commit_range) do
      revert(range, options)
    end
  end

  defp revert(range, options) do
    opts =
      [
        range: range,
        time: XSD.DateTime.value(options[:committed_at]),
        committer: Helper.committer(options[:committed_by])
      ]
      |> set_message(options)

    with {:ok, commit} <- Ontogen.revert(opts) do
      success(Helper.commit_info(commit))
    end
  end

  defp set_message(opts, %{message: nil}), do: opts
  defp set_message(opts, %{message: message}), do: Keyword.put(opts, :message, message)
end
