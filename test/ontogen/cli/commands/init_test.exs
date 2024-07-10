defmodule Ontogen.CLI.Commands.InitTest do
  use Ontogen.CLI.Case

  doctest Ontogen.CLI.Commands.Init

  alias Ontogen.Config.Loader

  @moduletag init: false

  test "without arguments", %{tmp_dir: dir} do
    assert {:error, _} = Ontogen.Config.service()

    assert {0, log} = capture_cli(~s[init])

    assert log =~ "Initialized empty Ontogen repository"

    assert_ontogen_dir(dir)

    assert {:ok, %Service{store: %Store{}}} = Ontogen.Config.service()
  end

  test "when .ontogen directory already exists" do
    File.mkdir_p!(".ontogen")

    assert {1, log} = capture_cli(~s[init])

    assert log =~ "Already initialized Ontogen repository found"
  end

  test "--adapter", %{tmp_dir: dir} do
    assert {:error, _} = Ontogen.Config.service()

    assert {0, log} = capture_cli(~s[init --adapter Fuseki])

    assert log =~ "Initialized empty Ontogen repository"

    assert_ontogen_dir(dir)

    assert {:ok, %Service{store: %Store.Adapters.Fuseki{}}} =
             Ontogen.Config.service()
  end

  test "--directory", %{tmp_dir: dir} do
    assert {:error, _} = Ontogen.Config.service()

    project_dir = "example"

    assert {0, log} = capture_cli(~s[init --directory #{project_dir}])

    assert log =~ "Initialized empty Ontogen repository"

    dir
    |> Path.join(project_dir)
    |> File.cd!(fn ->
      assert_ontogen_dir()

      assert {:ok, %Service{store: %Store{}}} = Ontogen.Config.service()
    end)
  end

  test "--template", %{tmp_dir: dir} do
    assert {:error, _} = Ontogen.Config.service()

    assert {0, log} = capture_cli(~s[init --template #{test_config_path()}])

    assert log =~ "Initialized empty Ontogen repository"

    assert_ontogen_dir(dir)

    assert Loader.load_graph() ==
             Loader.load_graph(load_path: test_config_path())

    Ontogen.Config.service()
  end

  defp assert_ontogen_dir, do: File.cwd!() |> assert_ontogen_dir()

  defp assert_ontogen_dir(dir) do
    config = Path.join(dir, Loader.local_path())
    assert File.exists?(config)
    assert File.exists?(Path.join(config, "agent.bog.ttl"))
    assert File.exists?(Path.join(config, "service.bog.ttl"))

    assert File.exists?(Path.join(dir, Ontogen.Bog.salt_base_path()))
  end
end
