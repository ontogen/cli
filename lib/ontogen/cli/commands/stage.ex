defmodule Ontogen.CLI.Stage do
  alias Ontogen.CLI.{Action, Helper}
  alias Ontogen.SpeechAct.Changeset
  alias Ontogen.NS.Og
  alias RDF.{Dataset, Graph, Description}

  @default_file "STAGE.nq"
  def default_file, do: @default_file

  @file_opt_spec [
    value_name: "STAGE_FILE",
    help: "Stage file with a RDF dataset of the changes",
    required: false,
    default: @default_file,
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
  def call(%{stage: file}, options, flags, []) do
    stage(options, Map.put(options, :stage, file || @default_file), flags)
  end

  def stage(changes, %{stage: stage_file} = options, _flags) do
    with {:ok, input_changeset} <- input_changeset(changes),
         {:ok, current_stage} <- load(stage_file, {:ok, nil}),
         {:ok, new_stage} <- new_stage(current_stage, input_changeset, options) do
      RDF.write_file(new_stage, stage_file, force: true)
    end
  end

  def load(file, on_missing \\ {:error, "no stage file found"}) do
    if File.exists?(file) do
      RDF.read_file(file)
    else
      case on_missing do
        fun when is_function(on_missing) -> fun.(file)
        on_missing -> on_missing
      end
    end
  end

  def load!(file, on_missing \\ {:error, "no stage file found"}) do
    case load(file, on_missing) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  def changeset(file_or_dataset \\ @default_file)

  def changeset(%Dataset{} = dataset) do
    Changeset.from_rdf(dataset, allow_empty: true)
  end

  def changeset(%Graph{}), do: raise("invalid changeset")

  def changeset(file), do: file |> load!() |> changeset()

  def speech_act_description(file_or_dataset \\ @default_file)

  def speech_act_description(%Dataset{} = dataset) do
    graph = Dataset.default_graph(dataset)

    case Graph.query(graph, {:speech_act?, :a, Og.SpeechAct}) do
      [] ->
        {:ok, nil}

      [%{speech_act: speech_act_id}] ->
        {:ok, graph[speech_act_id]}

      multiple ->
        ids = Enum.flat_map(multiple, &Map.values/1)
        {:error, "multiple speech acts found: #{Enum.join(ids, ", ")}"}
    end
  end

  def speech_act_description(file), do: file |> load!() |> speech_act_description()

  defp new_stage(nil, input_changeset, options) do
    {:ok,
     input_changeset
     |> Changeset.to_rdf()
     |> Dataset.add(new_speech_act(options))}
  end

  defp new_stage(current_stage, input_changeset, options) do
    with {:ok, changeset} <-
           current_stage
           |> changeset()
           |> Changeset.update(input_changeset)
           |> Changeset.validate(),
         {:ok, current_speech_act} <- speech_act_description(current_stage) do
      {:ok,
       current_stage
       |> clear_changes()
       |> Dataset.put(Changeset.to_rdf(changeset))
       |> Dataset.put(update_speech_act(current_speech_act, options))}
    end
  end

  defp new_speech_act(options, init \\ true) do
    created_at = options[:created_at]
    data_source = options[:data_source] |> List.wrap() |> Enum.map(&RDF.iri/1)

    speakers =
      case options[:created_by] do
        [] when init -> [Helper.user_iri()]
        speakers -> Enum.map(speakers, &RDF.iri/1)
      end

    RDF.bnode()
    |> RDF.type(Og.SpeechAct)
    |> Og.speaker(speakers)
    |> Og.dataSource(data_source)
    |> PROV.endedAtTime(List.wrap(created_at))
  end

  defp update_speech_act(nil, options), do: new_speech_act(options)

  defp update_speech_act(description, options) do
    description
    |> Description.delete_predicates(PROV.endedAtTime())
    |> Description.add(new_speech_act(options, false))
  end

  defp input_changeset(changes) do
    changes
    |> Enum.filter(fn {action, _} -> action in Changeset.fields() end)
    |> Enum.reduce_while({:ok, Changeset.empty()}, fn {action, files}, {:ok, changeset} ->
      Enum.reduce_while(files, {:ok, changeset}, fn file, {:ok, changeset} ->
        case RDF.read_file(file) do
          {:ok, %RDF.Dataset{graphs: graphs}} when map_size(graphs) == 0 ->
            {:cont, {:ok, changeset}}

          {:ok, %RDF.Dataset{graphs: %{nil: data} = graphs}} when map_size(graphs) == 1 ->
            {:cont, {:ok, Changeset.update(changeset, [{action, data}])}}

          {:ok, %RDF.Dataset{}} ->
            {:halt, {:error, "Invalid change file #{file}. Named graphs are not supported, yet."}}

          {:ok, data} ->
            {:cont, {:ok, Changeset.update(changeset, [{action, data}])}}

          error ->
            {:halt, error}
        end
      end)
      |> case do
        {:ok, _} = ok -> {:cont, ok}
        error -> {:halt, error}
      end
    end)
  end

  defp clear_changes(%Dataset{} = dataset) do
    Dataset.delete_graph(dataset, [Og.Addition, Og.Removal, Og.Update, Og.Replacement])
  end
end
