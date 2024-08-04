defmodule Ontogen.CLI.Helper do
  alias RDF.XSD
  alias Ontogen.Store

  import Ontogen.Utils
  import Ontogen.IdUtils, only: [to_hash: 1]

  @message_category_colors %{
    success: :green,
    info: :blue,
    warning: :yellow,
    error: :red
  }

  def puts(%{__exception__: true} = exception, category) do
    exception |> Exception.message() |> puts(category)
  end

  def puts(string, category) when is_binary(string) do
    string
    |> Owl.Data.tag(@message_category_colors[category])
    |> Owl.IO.puts()
  end

  def info(message), do: puts(message, :info)
  def success(message), do: puts(message, :success)
  def warning(message), do: puts(message, :warning)
  def error(message), do: puts(message, :error)

  def error_result(error) do
    error(error)
    1
  end

  def color_flags do
    [
      color: [
        long: "--color",
        help: "Enforce use of colors"
      ],
      no_color: [
        long: "--no-color",
        help: "Do not use colors in the output"
      ]
    ]
  end

  def set_color(opts, %{color: false, no_color: false}),
    do: Keyword.put(opts, :color, IO.ANSI.enabled?())

  def set_color(_, %{color: true, no_color: true}),
    do: raise(ArgumentError, "both flags --color and --no-color set")

  def set_color(opts, %{color: true}), do: Keyword.put(opts, :color, true)
  def set_color(opts, %{no_color: true}), do: Keyword.put(opts, :color, false)

  def valid_xsd_datetime(string) do
    datetime = XSD.datetime(string)

    if XSD.DateTime.valid?(datetime) do
      {:ok, datetime}
    else
      {:error, "invalid datetime"}
    end
  end

  def user, do: Ontogen.Config.user!()
  def user_iri, do: user().__id__
  def user_id, do: to_string(user_iri())

  def adapter_types do
    Enum.map_join(Store.adapters(), ", ", &Store.Adapter.type_name/1) <>
      " or Generic for the generic store adapter"
  end

  def to_adapter(nil), do: {:ok, nil}
  def to_adapter("generic"), do: {:ok, nil}
  def to_adapter("Generic"), do: {:ok, nil}
  def to_adapter("Store"), do: {:ok, nil}

  def to_adapter(adapter_name) when is_binary(adapter_name) do
    if adapter = Store.Adapter.type(adapter_name) do
      {:ok, adapter}
    else
      {:error,
       "invalid store adapter: #{inspect(adapter_name)}; available adapters: #{adapter_types()}"}
    end
  end

  def commit_info(commit) do
    root_commit = if Ontogen.Commit.root?(commit), do: "(root-commit) "

    insertions_count =
      ((commit.add && RTC.Compound.triple_count(commit.add.statements)) || 0) +
        ((commit.update && RTC.Compound.triple_count(commit.update.statements)) || 0) +
        ((commit.replace && RTC.Compound.triple_count(commit.replace.statements)) || 0)

    deletions_count = (commit.remove && RTC.Compound.triple_count(commit.remove.statements)) || 0

    overwrites_count =
      (commit.overwrite && RTC.Compound.triple_count(commit.overwrite.statements)) || 0

    """
    [#{root_commit}#{to_hash(commit)}] #{first_line(commit.message)}
     #{insertions_count} insertions, #{deletions_count} deletions, #{overwrites_count} overwrites
    """
  end
end
