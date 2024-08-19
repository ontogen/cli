defmodule Ontogen.CLI.Commands.Changeset do
  alias Ontogen.{Commit, Changeset}

  use Ontogen.CLI.Command,
    name: :changeset,
    about: "Shows the combined changes in a commit range.",
    args: [
      range: [
        value_name: "COMMIT_RANGE",
        help: "Range of commits to show changes for.",
        required: true,
        parser: :string
      ]
    ],
    options: [
      resource: [
        long: "--resource",
        value_name: "IRI",
        help: "Filters commits with changes having the given resource as subject.",
        parser: :string
      ]
    ],
    flags:
      [
        stat: [
          long: "--stat",
          help: "Generates a diffstat"
        ],
        short_stat: [
          long: "--shortstat",
          help:
            "Output only the last line of the --stat format containing total number of modified resources, as well as number of added and deleted triples"
        ],
        resource_only: [
          long: "--resource-only",
          help: "Show only IRIs of changed resources"
        ],
        changes: [
          long: "--changes",
          help:
            "Show the actual changes of changesets (default unless other changeset formats are selected)"
        ]
      ] ++ color_flags()

  @impl true
  def handle_call(%{range: range_spec}, options, flags, []) do
    with {:ok, range} <- Commit.Range.parse(range_spec, single_ref_as: :single_commit_range),
         {:ok, changeset} <- changeset(range, options) do
      if Commit.Changeset.empty?(changeset) do
        IO.puts("No changes.")
      else
        format_opts = set_color([], flags)

        Enum.each(changeset_formats(flags), fn format ->
          changeset
          |> Changeset.Formatter.format(format, format_opts)
          |> IO.puts()
        end)
      end
    end
  end

  defp changeset(range, options) do
    [range: range]
    |> set_subject(options)
    |> Ontogen.changeset()
  end

  defp changeset_formats(flags) do
    Enum.flat_map(Changeset.Formatter.formats(), fn format ->
      if flags[format], do: [format], else: []
    end)
    |> case do
      [] -> [:changes]
      formats -> formats
    end
  end

  defp set_subject(opts, %{resource: nil}), do: opts

  defp set_subject(opts, %{resource: resource}),
    do: Keyword.put(opts, :resource, resource)
end
