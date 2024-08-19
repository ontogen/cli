defmodule Ontogen.CLI.Commands.Init do
  alias Ontogen.CLI.Helper
  alias Ontogen.Config.Generator

  use Ontogen.CLI.Command,
    name: :init,
    about: "Creates the configuration files of a new Ontogen repository",
    args: [],
    options: [
      store_adapter: [
        value_name: "STORE_ADAPTER",
        long: "--adapter",
        help: "Name of the store adapter",
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
      ],
      template: [
        value_name: "TEMPLATE_DIRECTORY",
        long: "--template",
        help: "Config template directory to be used to generate the local config",
        parser: :string,
        required: false
      ]
    ]

  def call(args, options, flags, unknown) do
    handle_call(args, options, flags, unknown)
  end

  @impl true
  def handle_call(%{}, options, _flags, []) do
    with {:ok, directory} <- setup_directory(options),
         :ok <- generate_config(directory, options) do
      File.cd!(directory, fn -> Ontogen.Bog.create_salt_base_path() end)

      success("Initialized empty Ontogen repository in #{directory}")
    end
  end

  defp setup_directory(options) do
    ontogen_dir = Ontogen.CLI.ontogen_dir(options)
    project_dir = Ontogen.CLI.project_dir(options)

    if File.exists?(ontogen_dir) do
      {:error, "Already initialized Ontogen repository found at #{project_dir}"}
    else
      with :ok <- File.mkdir_p(ontogen_dir) do
        {:ok, project_dir}
      end
    end
  end

  defp generate_config(directory, options) do
    with {:ok, adapter} <- Helper.to_adapter(options[:store_adapter]) do
      opts =
        if template = options[:template] do
          [template_dir: template]
        else
          []
        end
        |> Keyword.put(:adapter, adapter)

      directory
      |> Path.join(Ontogen.Config.Loader.local_path())
      |> Generator.generate(opts)
    end
  end
end
