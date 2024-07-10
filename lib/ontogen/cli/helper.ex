defmodule Ontogen.CLI.Helper do
  alias RDF.XSD

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

  def valid_xsd_datetime(string) do
    datetime = XSD.datetime(string)

    if XSD.DateTime.valid?(datetime) do
      {:ok, datetime}
    else
      {:error, "invalid datetime"}
    end
  end

  def user_iri, do: Ontogen.Config.user!().__id__
  def user_id, do: to_string(user_iri())

  def adapter_types do
    "e.g. Oxigraph or Generic"
  end

  def adapter_type(string) do
    if adapter = Ontogen.Store.Adapter.type(string) do
      {:ok, adapter}
    else
      {:error,
       "invalid store adapter: #{inspect(string)}; available adapters: #{adapter_types()}"}
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
