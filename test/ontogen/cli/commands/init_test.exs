defmodule Ontogen.CLI.InitTest do
  use Ontogen.CLI.StoreCase, async: false

  doctest Ontogen.CLI.Init

  alias Ontogen.{CLI, Repository}

  import Ontogen.CLI.TestHelper
  import Ontogen.CLI.Helper
  import ExUnit.CaptureIO

  setup do
    cwd = File.cwd!()
    tmp_dir = cd_tmp_dir!()
    on_exit(fn -> File.cd!(cwd) end)

    [dir: tmp_dir]
  end

  setup {Ontogen.CLI.TestHelper, :configless_ontogen}

  @repo_id "http://example.repo.com/"
  @dataset_id "http://example.repo.com/dataset"
  @prov_graph_id "http://example.repo.com/prov"

  @valid_repo_opts "#{@repo_id} --dataset #{@dataset_id} --prov-graph #{@prov_graph_id}"
  @valid_store_opts "--query-url http://localhost:7879/query --update-url http://localhost:7879/update --graph-store-url http://localhost:7879/store"

  test "with explicitly specified repo URIs and store endpoints", %{dir: dir} do
    assert {0, log} =
             with_io(fn ->
               CLI.main(~w[init #{@valid_repo_opts} #{@valid_store_opts}])
             end)

    assert log =~ "Initialized empty Ontogen repository #{@repo_id} in"

    assert_ontogen_dir(dir)
    assert config_available?()

    :ok = reboot_ontogen()

    assert Ontogen.repository() ==
             Repository.build!(@repo_id,
               dataset: Ontogen.Dataset.build!(@dataset_id),
               prov_graph: Ontogen.ProvGraph.build!(@prov_graph_id)
             )
  end

  test "without local and global store config" do
    assert {1, log} = with_io(fn -> CLI.main(~w[init #{@valid_repo_opts}]) end)

    assert log =~
             "No store options provided for local configuration. These options are required as no store is defined in the global configuration."
  end

  @complete_config Path.expand("test/data/config/complete_config.ttl")
  test "without local store config, but with global store config", %{dir: dir} do
    File.cp!(@complete_config, Ontogen.Config.path(:system))
    :ok = reboot_ontogen()

    assert {0, log} =
             with_io(fn ->
               CLI.main(~w[init #{@valid_repo_opts}])
             end)

    assert log =~ "Initialized empty Ontogen repository #{@repo_id} in"

    assert_ontogen_dir(dir, with_config: false)
    assert config_available?()

    :ok = reboot_ontogen()

    assert Ontogen.repository() ==
             Repository.build!(@repo_id,
               dataset: Ontogen.Dataset.build!(@dataset_id),
               prov_graph: Ontogen.ProvGraph.build!(@prov_graph_id)
             )
  after
    File.rm!(Ontogen.Config.path(:system))
  end

  test "--directory" do
    custom_dir = Path.join(tmp_dir!(), "custom")

    assert {0, log} =
             with_io(fn ->
               CLI.main(
                 ~w[init #{@valid_repo_opts} #{@valid_store_opts} --directory #{custom_dir}]
               )
             end)

    assert log =~ "Initialized empty Ontogen repository #{@repo_id} in"

    assert_ontogen_dir(custom_dir)
    assert config_available?()

    File.cd!(custom_dir)

    :ok = reboot_ontogen()

    assert Ontogen.repository() ==
             Repository.build!(@repo_id,
               dataset: Ontogen.Dataset.build!(@dataset_id),
               prov_graph: Ontogen.ProvGraph.build!(@prov_graph_id)
             )
  end

  test "when repository already exists", %{dir: dir} do
    dir |> Path.join(".ontogen") |> File.mkdir!()
    dir |> Path.join(".ontogen/repo") |> File.touch!()

    assert {1, log} =
             with_io(fn ->
               CLI.main(~w[init #{@valid_repo_opts} #{@valid_store_opts}])
             end)

    assert log =~ "Already initialized Ontogen repository found"
  end

  defp assert_ontogen_dir(dir, opts \\ []) do
    ontogen_dir = Path.join(dir, ".ontogen")
    assert File.exists?(ontogen_dir)

    config = Path.join(ontogen_dir, "test_config.ttl")

    if Keyword.get(opts, :with_config, true) do
      assert File.exists?(config)
    else
      refute File.exists?(config)
    end

    assert ontogen_dir |> Path.join("repo") |> File.exists?()
  end
end
