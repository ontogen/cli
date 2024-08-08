defmodule Ontogen.CLI.Commands.CommitTest do
  use Ontogen.CLI.RepositoryCase, async: false

  doctest Ontogen.CLI.Commands.Commit

  alias Ontogen.CLI.Stage
  alias RDF.{Graph, Dataset}

  test "with pre-staged changes and defaults" do
    {graph, file} = graph_file([1, 2])

    message = "Initial commit"

    assert cli(
             ~s[add #{file} --created-by #{id(:agent)} --created-at #{DateTime.to_iso8601(datetime())}]
           ) == 0

    assert File.exists?(Stage.default_file())

    assert {0, log} = capture_cli(~s[commit --message "#{message}"])

    refute File.exists?(Stage.default_file())

    assert {:ok, [%Ontogen.Commit{} = commit]} = Ontogen.log()
    assert DateTime.diff(commit.time, DateTime.utc_now(), :second) <= 1
    assert commit.committer == user()
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

    assert cli(~s[update #{file} --created-at #{DateTime.to_iso8601(datetime(-1, :hour))}]) ==
             0

    assert File.exists?(Stage.default_file())

    assert {0, log} =
             capture_cli(
               ~s[commit --message #{message} --committed-by #{id(:agent)} --committed-at #{DateTime.to_iso8601(datetime())}]
             )

    refute File.exists?(Stage.default_file())

    assert {:ok, [%Ontogen.Commit{} = commit]} = Ontogen.log()
    assert commit.time == datetime()
    assert commit.committer == id(:agent)
    assert commit.message == message
    assert Ontogen.Proposition.graph(commit.update) == graph

    assert commit.speech_act.speaker == user_iri()
    assert commit.speech_act.time == datetime(-1, :hour)

    assert log =~ "[(root-commit) #{Ontogen.IdUtils.to_hash(commit)}] #{message}"
    assert log =~ "2 insertions, 0 deletions, 0 overwrites"
  end

  test "with non-ISO 8601 time format" do
    {_graph, file} = graph_file([1, 2])

    assert cli(~s[update #{file} --created-at 2016-02-29T22:25:00]) ==
             0

    assert {0, _} =
             capture_cli(
               ~s[commit --message Foo --committed-at 01/01/2018 --committed-by #{id(:agent)}]
             )

    assert {:ok, [%Ontogen.Commit{} = commit]} = Ontogen.log()
    assert commit.committer == id(:agent)
    assert commit.time == ~N[2018-01-01 00:00:00]
    assert commit.speech_act.time == ~N[2016-02-29 22:25:00]
  end

  test "with staging" do
    {graph, file} = graph_file([1, 2])
    message = "Foo"

    refute File.exists?(Stage.default_file())

    assert {0, log} =
             capture_cli(
               ~s[commit --add #{file} --created-by #{id(:agent)} --created-at #{DateTime.to_iso8601(datetime())} --message #{message}]
             )

    refute File.exists?(Stage.default_file())

    assert {:ok, [%Ontogen.Commit{} = commit]} = Ontogen.log()
    assert DateTime.diff(commit.time, DateTime.utc_now(), :second) <= 1
    assert commit.committer == user()
    assert commit.message == message
    assert Ontogen.Proposition.graph(commit.add) == graph

    assert commit.speech_act.speaker == id(:agent)
    assert commit.speech_act.time == datetime()

    assert log =~ "[(root-commit) #{Ontogen.IdUtils.to_hash(commit)}] #{message}"
    assert log =~ "2 insertions, 0 deletions, 0 overwrites"
  end

  test "no stage file" do
    assert {1, log} = capture_cli(~s[commit --message Missing])

    assert log =~ "no stage file found"
  end

  test "empty changeset" do
    File.touch(Stage.default_file())

    assert {1, log} = capture_cli(~s[commit --message Nothing])

    assert log =~ "empty stage"
  end

  test "no effective changes" do
    {_graph, file} = graph_file([1, 2])

    assert cli(~s[add #{file}]) == 0
    assert {0, _} = capture_cli(~s[commit --message Commit1])
    assert cli(~s[add #{file}]) == 0
    assert {1, log} = capture_cli(~s[commit --message Commit2])

    assert log =~ "No effective changes."
  end

  test "additional statements in stage file are stored in the history graph" do
    {graph, file} = graph_file([1, 2])

    assert cli(
             ~s[add #{file} --created-by #{id(:agent)} --created-at #{DateTime.to_iso8601(datetime())}]
           ) == 0

    stage = Stage.load!(Stage.default_file())
    {:ok, speech_act} = Stage.speech_act_description(stage)

    stage
    |> Dataset.add(speech_act |> EX.p(EX.O))
    |> Dataset.add(statement(1))
    |> RDF.write_file!(Stage.default_file(), force: true)

    assert {0, _log} = capture_cli(~s[commit --message Foo])

    assert {:ok, [%Ontogen.Commit{} = commit]} = Ontogen.log()
    assert Ontogen.Proposition.graph(commit.add) == graph

    assert commit.speech_act.speaker == id(:agent)
    assert commit.speech_act.time == datetime()

    assert Grax.additional_statements(commit.speech_act) ==
             commit.speech_act.__id__
             |> RDF.type(Og.SpeechAct)
             |> EX.p(EX.O)

    assert Ontogen.history!() |> Graph.include?(statement(1))
  end
end
