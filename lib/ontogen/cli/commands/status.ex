defmodule Ontogen.CLI.Commands.Status do
  alias Ontogen.CLI.Stage
  alias Ontogen.Commit
  alias Ontogen.{Commit, Changeset, FormatterHelper}

  use Ontogen.CLI.Command,
    name: :status,
    about: "Show the status of the staged changes.",
    args: [
      stage: Ontogen.CLI.Commands.Stage.file_opt_spec()
    ],
    options: [
      hash_format: [
        long: "--hash-format",
        value_name: "STRING",
        help:
          "Hash format. Possible values: #{Enum.join(FormatterHelper.hash_formats(), ", ")} (Default is format specific)",
        parser: :string
      ]
    ],
    flags: color_flags()

  @impl true
  def handle_call(%{stage: file}, options, flags, []) do
    opts =
      []
      |> set_color(flags)
      |> set_hash_format(options)

    stage_file = file || Stage.default_file()

    with {:ok, change_dataset} <- Stage.load(stage_file),
         changeset = Stage.changeset(change_dataset),
         {:ok, speech_act, _metadata} <- Stage.speech_act(change_dataset),
         resources = changeset |> Ontogen.Changeset.Helper.subjects() |> MapSet.to_list(),
         {:ok, %Commit.Changeset{} = effective_changes} <-
           Ontogen.effective_changeset(changeset),
         {:ok, current_revisions} <- Ontogen.revision(resources),
         {:ok, prospective_commit} <- prospective_commit(speech_act, effective_changes) do
      [
        Commit.Formatter.format(prospective_commit, :speech_act, opts),
        "\n\n",
        changes(prospective_commit, current_revisions, opts)
      ]
      |> IO.puts()
    else
      {:ok, %Ontogen.NoEffectiveChanges{}} ->
        IO.puts("No effective changes.")

      error ->
        error
    end
  end

  defp prospective_commit(speech_act, effective_changes) do
    Commit.new(changeset: effective_changes, speech_act: speech_act)
  end

  defp changes(prospective_commit, current_revisions, opts) do
    Changeset.Formatter.format(prospective_commit, :combined_changes,
      context_data: current_revisions,
      color: opts[:color]
    )
  end

  defp set_hash_format(opts, %{hash_format: nil}), do: opts

  defp set_hash_format(opts, %{hash_format: hash_format}),
    do: Keyword.put(opts, :hash_format, String.to_atom(hash_format))
end
