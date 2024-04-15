defmodule Ontogen.CLI.Commands.Init do
  alias Ontogen.CLI.Helper

  use Ontogen.CLI.Command,
    name: :init,
    about: "Create an empty Ontogen repository",
    args: [
      repo_uri: [
        value_name: "REPO_URI",
        help: "URI of the repository",
        required: true,
        parser: :string
      ]
    ],
    options: [
      dataset_uri: [
        value_name: "DATASET_URI",
        long: "--dataset",
        help: "URI of the dataset",
        parser: :string,
        required: true
      ],
      prov_graph_uri: [
        value_name: "PROV_GRAPH_URI",
        long: "--prov-graph",
        help: "URI of the prov graph",
        parser: :string,
        required: true
      ],
      store_adapter: [
        value_name: "STORE_ADAPTER",
        long: "--store-adapter",
        help: "Name of the store adapter; #{Helper.adapter_types()} (Default: Oxigraph)",
        parser: &Helper.adapter_type/1,
        required: false
      ],
      store_query_endpoint: [
        value_name: "QUERY_URL",
        long: "--query-url",
        help: "URL of the SPARQL query endpoint of the store hosting the repository",
        parser: :string,
        required: false
      ],
      store_update_endpoint: [
        value_name: "UPDATE_URL",
        long: "--update-url",
        help: "URL of the SPARQL update endpoint of the store hosting the repository",
        parser: :string,
        required: false
      ],
      store_graph_store_endpoint: [
        value_name: "GRAPH_STORE_URL",
        long: "--graph-store-url",
        help: "URL of the SPARQL graph store endpoint of the store hosting the repository",
        parser: :string,
        required: false
      ],
      directory: [
        value_name: "DIRECTORY",
        long: "--directory",
        help:
          "Base directory of the repository (within which the .ontogen/ subdirectory is created)",
        parser: :string,
        required: false
      ]
    ]

  alias Ontogen.{Repository, Dataset, ProvGraph}

  @ontogen_dir ".ontogen"

  @impl true
  def call(%{repo_uri: repo_uri}, options, _flags, []) do
    with {:ok, directory} <- setup_directory(options),
         :ok <- create_local_config(options, directory) do
      File.cd!(directory, fn ->
        with :ok <- reboot_ontogen(),
             {:ok, _repository} <- create_repository(repo_uri, options) do
          success("Initialized empty Ontogen repository #{repo_uri} in #{directory}")
        end
      end)
    end
  end

  defp setup_directory(options) do
    project_dir = options[:directory] || File.cwd!()

    if project_dir
       |> Path.join(Ontogen.Config.Repository.IdFile.path())
       |> File.exists?() do
      {:error, "Already initialized Ontogen repository found at #{project_dir}"}
    else
      with :ok <- project_dir |> ontogen_dir() |> File.mkdir_p() do
        {:ok, project_dir}
      end
    end
  end

  defp create_local_config(
         %{
           store_adapter: store_adapter,
           store_query_endpoint: store_query_endpoint,
           store_update_endpoint: store_update_endpoint,
           store_graph_store_endpoint: store_graph_store_endpoint
         },
         directory
       )
       when not is_nil(store_query_endpoint) and
              not is_nil(store_update_endpoint) and
              not is_nil(store_graph_store_endpoint) do
    adapter_type = store_adapter || Ontogen.Store.Oxigraph
    config_path = Path.expand(Ontogen.Config.path(:local), directory)

    with {:ok, adapter} <-
           adapter_type.build(
             query_endpoint: store_query_endpoint,
             update_endpoint: store_update_endpoint,
             graph_store_endpoint: store_graph_store_endpoint
           ),
         {:ok, config} <- Ontogen.Config.new(store: adapter),
         {:ok, config_graph} <- Ontogen.Config.to_rdf(config, validate: false) do
      RDF.Turtle.write_file(config_graph, config_path)
    end
  end

  defp create_local_config(_options, _directory) do
    if config_available?() do
      :ok
    else
      {:error,
       "No store options provided for local configuration. These options are required as no store is defined in the global configuration."}
    end
  end

  defp create_repository(repo_uri, %{dataset_uri: dataset_uri, prov_graph_uri: prov_graph_uri}) do
    with {:ok, repository} <-
           Repository.new(repo_uri,
             dataset: Dataset.build!(dataset_uri),
             prov_graph: ProvGraph.build!(prov_graph_uri)
           ) do
      Ontogen.create_repo(repository)
    end
  end

  defp ontogen_dir(dir), do: Path.join(dir, @ontogen_dir)
end
