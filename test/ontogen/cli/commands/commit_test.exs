defmodule Ontogen.CLI.CommitTest do
  use Ontogen.CLI.RepositoryCase, async: false

  doctest Ontogen.CLI.Commit

  alias Ontogen.CLI.Stage
  alias RDF.{Graph, Dataset}

  test "with pre-staged changes and defaults" do
    {graph, file} = graph_file([1, 2])

    message = "Foo"

    assert CLI.main(
             ~w[add #{file} --created-by #{id(:agent)} --created-at #{DateTime.to_iso8601(datetime())}]
           ) == 0

    assert File.exists?(Stage.default_file())

    assert {0, log} =
             with_io(fn ->
               CLI.main(~w[commit --message #{message}])
             end)

    refute File.exists?(Stage.default_file())

    assert {:ok, [%Ontogen.Commit{} = commit]} = Ontogen.dataset_history()
    assert DateTime.diff(commit.time, DateTime.utc_now(), :second) <= 1
    assert commit.committer == user_iri()
    assert commit.message == message
    assert Ontogen.Proposition.graph(commit.add) == graph

    assert commit.speech_act.speaker == id(:agent)
    assert commit.speech_act.time == datetime()

    assert log =~ "[(root-commit) #{Ontogen.IdUtils.to_hash(commit)}] #{message}"
    assert log =~ "2 insertions, 0 deletions, 0 overwrites"
  end

  test "committed-by and committed-at" do
    {graph, file} = graph_file([1, 2])

    message = "Foo"

    assert CLI.main(~w[update #{file} --created-at #{DateTime.to_iso8601(datetime(-1, :hour))}]) ==
             0

    assert File.exists?(Stage.default_file())

    assert {0, log} =
             with_io(fn ->
               CLI.main(
                 ~w[commit --message #{message} --committed-by #{id(:agent)} --committed-at #{DateTime.to_iso8601(datetime())}]
               )
             end)

    refute File.exists?(Stage.default_file())

    assert {:ok, [%Ontogen.Commit{} = commit]} = Ontogen.dataset_history()
    assert commit.time == datetime()
    assert commit.committer == id(:agent)
    assert commit.message == message
    assert Ontogen.Proposition.graph(commit.update) == graph

    assert commit.speech_act.speaker == user_iri()
    assert commit.speech_act.time == datetime(-1, :hour)

    assert log =~ "[(root-commit) #{Ontogen.IdUtils.to_hash(commit)}] #{message}"
    assert log =~ "2 insertions, 0 deletions, 0 overwrites"
  end

  test "with staging" do
    {graph, file} = graph_file([1, 2])
    message = "Foo"

    refute File.exists?(Stage.default_file())

    assert {0, log} =
             with_io(fn ->
               CLI.main(
                 ~w[commit --add #{file} --created-by #{id(:agent)} --created-at #{DateTime.to_iso8601(datetime())} --message #{message}]
               )
             end)

    refute File.exists?(Stage.default_file())

    assert {:ok, [%Ontogen.Commit{} = commit]} = Ontogen.dataset_history()
    assert DateTime.diff(commit.time, DateTime.utc_now(), :second) <= 1
    assert commit.committer == user_iri()
    assert commit.message == message
    assert Ontogen.Proposition.graph(commit.add) == graph

    assert commit.speech_act.speaker == id(:agent)
    assert commit.speech_act.time == datetime()

    assert log =~ "[(root-commit) #{Ontogen.IdUtils.to_hash(commit)}] #{message}"
    assert log =~ "2 insertions, 0 deletions, 0 overwrites"
  end

  test "no stage file" do
    assert {1, log} =
             with_io(fn ->
               CLI.main(~w[commit --message Missing])
             end)

    assert log =~ "no stage file found"
  end

  test "empty changeset" do
    File.touch(Stage.default_file())

    assert {1, log} =
             with_io(fn ->
               CLI.main(~w[commit --message Nothing])
             end)

    assert log =~ "empty stage"
  end

  test "no effective changes" do
    {_graph, file} = graph_file([1, 2])

    assert CLI.main(~w[add #{file}]) == 0

    assert {0, _} =
             with_io(fn ->
               CLI.main(~w[commit --message Commit1])
             end)

    assert CLI.main(~w[add #{file}]) == 0

    assert {1, log} =
             with_io(fn ->
               CLI.main(~w[commit --message Commit2])
             end)

    assert log =~ "No effective changes."
  end

  test "additional statements in stage file are stored in the PROV graph?" do
    {graph, file} = graph_file([1, 2])

    assert CLI.main(
             ~w[add #{file} --created-by #{id(:agent)} --created-at #{DateTime.to_iso8601(datetime())}]
           ) == 0

    stage = Stage.load!(Stage.default_file())
    {:ok, speech_act} = Stage.speech_act_description(stage)

    stage
    |> Dataset.add(speech_act |> EX.p(EX.O))
    |> Dataset.add(statement(1))
    |> RDF.write_file!(Stage.default_file(), force: true)

    assert {0, _log} =
             with_io(fn ->
               CLI.main(~w[commit --message Foo])
             end)

    assert {:ok, [%Ontogen.Commit{} = commit]} = Ontogen.dataset_history()
    assert Ontogen.Proposition.graph(commit.add) == graph

    assert commit.speech_act.speaker == id(:agent)
    assert commit.speech_act.time == datetime()

    assert Grax.additional_statements(commit.speech_act) ==
             commit.speech_act.__id__
             |> RDF.type(Og.SpeechAct)
             |> EX.p(EX.O)

    assert Ontogen.prov_graph!() |> Graph.include?(statement(1))
  end
  end
end
