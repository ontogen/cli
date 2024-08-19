defmodule Ontogen.CLI.Commands.Log do
  alias Ontogen.{Commit, Changeset, FormatterHelper}

  use Ontogen.CLI.Command,
    name: :log,
    about: "Show commit logs",
    args: [
      range: [
        value_name: "COMMIT_RANGE",
        help: "Range of commits to show",
        required: false,
        parser: :string
      ]
    ],
    options: [
      format: [
        long: "--format",
        value_name: "STRING",
        help: "Log format. Possible values: #{Enum.join(Commit.Formatter.formats(), ", ")}",
        default: "default",
        parser: :string
      ],
      hash_format: [
        long: "--hash-format",
        value_name: "STRING",
        help:
          "Hash format. Possible values: #{Enum.join(FormatterHelper.hash_formats(), ", ")} (Default is format specific)",
        parser: :string
      ],
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
            "Output only the last line of the --stat format containing total number of modified resources, as well as number of added and deleted triples."
        ],
        resource_only: [
          long: "--resource-only",
          help: "Shows the IRIs of changed resources"
        ],
        changes: [
          long: "--commit-changes",
          help:
            "Show the commit changes, i.e. only the effectively required changes of the speech act."
        ],
        speech_changes: [
          long: "--speech-changes",
          help: "Show the changes of the speech act."
        ],
        combined_changes: [
          long: "--changes",
          help:
            "Show changes of the commit including the ignored statements of the speech act highlighted."
        ],
        reverse: [
          long: "--reverse",
          help: "Output the commits chosen to be shown in reverse order."
        ],
        commit_date_order: [
          long: "--date-order",
          help:
            "Sort commits by descending commit time. Can be combined with --reverse for ascending ordering"
        ],
        author_date_order: [
          long: "--author-date-order",
          help:
            "Sort commits by descending speech act time. Can be combined with --reverse for ascending ordering"
        ]
      ] ++ color_flags()

  @impl true
  def handle_call(%{range: spec}, options, flags, []) do
    with {:ok, range} <- range(spec),
         {:ok, log_stream} <- formatted_log(range, options, flags) do
      log_stream
      |> Stream.each(&IO.write/1)
      |> Stream.run()

      IO.puts("")
    end
  end

  defp range(nil), do: Commit.Range.new(:root, :head)
  defp range(spec), do: Commit.Range.parse(spec)

  defp formatted_log(range, options, flags) do
    [
      range: range,
      type: :formatted,
      stream: true
    ]
    |> set_format(options)
    |> set_hash_format(options)
    |> set_changeset_formats(flags)
    |> set_color(flags)
    |> set_order(flags)
    |> set_subject(options)
    |> Ontogen.log()
  end

  defp set_format(opts, %{format: nil}), do: opts

  defp set_format(opts, %{format: format}),
    do: Keyword.put(opts, :format, String.to_atom(format))

  defp set_changeset_formats(opts, flags),
    do: Keyword.put(opts, :changes, extract_changeset_formats(flags))

  defp extract_changeset_formats(flags) do
    Enum.flat_map(Changeset.Formatter.formats(), fn format ->
      if flags[format], do: [format], else: []
    end)
  end

  defp set_hash_format(opts, %{hash_format: nil}), do: opts

  defp set_hash_format(opts, %{hash_format: hash_format}),
    do: Keyword.put(opts, :hash_format, String.to_atom(hash_format))

  defp set_order(opts, %{commit_date_order: false, author_date_order: false, reverse: reverse}),
    do: Keyword.put(opts, :order, if(reverse, do: :asc, else: :desc))

  defp set_order(_, %{commit_date_order: true, author_date_order: true}),
    do: raise(ArgumentError, "both flags --date-order and --author-date-order set")

  defp set_order(opts, %{commit_date_order: true, reverse: reverse}),
    do: Keyword.put(opts, :order, {:time, if(reverse, do: :asc, else: :desc)})

  defp set_order(opts, %{author_date_order: true, reverse: reverse}),
    do: Keyword.put(opts, :order, {:speech_time, if(reverse, do: :asc, else: :desc)})

  defp set_subject(opts, %{resource: nil}), do: opts

  defp set_subject(opts, %{resource: resource}),
    do: Keyword.put(opts, :resource, resource)
end
