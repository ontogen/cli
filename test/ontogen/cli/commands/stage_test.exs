defmodule Ontogen.CLI.Commands.StageTest do
  use Ontogen.CLI.RepositoryCase

  doctest Ontogen.CLI.Commands.Add
  doctest Ontogen.CLI.Commands.Update
  doctest Ontogen.CLI.Commands.Replace
  doctest Ontogen.CLI.Commands.Remove
  doctest Ontogen.CLI.Commands.Stage

  alias Ontogen.CLI.Stage
  alias Ontogen.SpeechAct.Changeset
  alias RDF.{Dataset, Graph, Description, Literal, XSD}

  import RDF.Namespace.IRI

  # All test in this file should at least perform two commands to test
  # with and without an existing stage file!

  describe "action commands" do
    test "various actions" do
      {graph1, file1} = graph_file([1, 2], prefixes: [ex: EX])
      {_, file2} = graph_file([2, 3], prefixes: [ex: EX, rdf: RDF])
      {_, file3} = graph_file([3, 4], prefixes: [ex: EX])

      refute File.exists?(Stage.default_file())

      assert cli(~s[add #{file1}]) == 0

      assert File.exists?(Stage.default_file())
      assert Stage.changeset() == Changeset.new!(add: graph1)
      assert {:ok, speech_act} = Stage.speech_act_description()
      assert_speech_act_match(speech_act)

      assert cli(~s[add #{file2} #{file3}]) == 0

      assert Stage.changeset() ==
               Changeset.new!(add: graph([1, 2, 3, 4], prefixes: [ex: EX, rdf: RDF]))

      assert {:ok, speech_act} = Stage.speech_act_description()
      assert_speech_act_match(speech_act)

      assert cli(~s[remove #{file3}]) == 0

      assert Stage.changeset() ==
               Changeset.new!(
                 add: graph([1, 2], prefixes: [ex: EX, rdf: RDF]),
                 remove: graph([3, 4], prefixes: [ex: EX, rdf: RDF])
               )

      assert cli(~s[update #{file2}]) == 0

      assert Stage.changeset() ==
               Changeset.new!(
                 add: graph([1], prefixes: [ex: EX, rdf: RDF]),
                 update: graph([2, 3], prefixes: [ex: EX, rdf: RDF]),
                 remove: graph([4], prefixes: [ex: EX, rdf: RDF])
               )

      assert cli(~s[replace #{file2} #{file3}]) == 0

      assert Stage.changeset() ==
               Changeset.new!(
                 add: graph([1], prefixes: [ex: EX, rdf: RDF]),
                 replace: graph([2, 3, 4], prefixes: [ex: EX, rdf: RDF])
               )
    end

    test "custom stage file" do
      {graph, file} = graph_file([1, 2])
      {_, file2} = graph_file([2, 3])
      {_, file3} = graph_file([3, 4])
      custom_stage_file = "custom_stage_file.nq"

      refute File.exists?(custom_stage_file)

      assert cli(~s[add #{file} --stage #{custom_stage_file}]) == 0

      assert File.exists?(custom_stage_file)
      assert Stage.changeset(custom_stage_file) == Changeset.new!(add: graph)
      assert {:ok, speech_act} = Stage.speech_act_description(custom_stage_file)
      assert_speech_act_match(speech_act)

      assert cli(~s[update #{file2} #{file3} --stage #{custom_stage_file}]) == 0

      assert Stage.changeset(custom_stage_file) ==
               Changeset.new!(
                 add: graph([1]),
                 update: graph([2, 3, 4])
               )

      assert {:ok, speech_act} = Stage.speech_act_description(custom_stage_file)
      assert_speech_act_match(speech_act)
    end

    test "speech act metadata" do
      {_, file1} = graph_file([1, 2])
      {_, file2} = graph_file([2, 3])
      speaker1 = RDF.iri(EX.Speaker1)
      speaker2 = RDF.iri(EX.Speaker2)
      speaker3 = RDF.iri(EX.Speaker3)

      time = "2015-01-23T23:50:07"
      assert cli(~s[add #{file1} --created-at #{time} --created-by #{speaker1}]) == 0

      assert {:ok, speech_act} = Stage.speech_act_description()
      assert_speech_act_match(speech_act, time: time, speaker: speaker1)

      time = "2015-01-23T23:59:07.123+02:30"

      assert cli(~s[add #{file2} #{file1} --created-at #{time} --created-by #{speaker2}]) ==
               0

      assert {:ok, speech_act} = Stage.speech_act_description()
      assert_speech_act_match(speech_act, time: time, speaker: [speaker1, speaker2])

      time = DateTime.to_iso8601(datetime())
      assert cli(~s[remove #{file2} --created-at #{time}]) == 0
      assert {:ok, speech_act} = Stage.speech_act_description()
      assert_speech_act_match(speech_act, time: time, speaker: [speaker1, speaker2])

      assert cli(~s[add #{file2} --created-by #{speaker1}]) == 0
      assert {:ok, speech_act} = Stage.speech_act_description()
      assert_speech_act_match(speech_act, time: :now, speaker: [speaker1, speaker2])

      assert cli(~s[update #{file2} --created-by #{speaker3}]) == 0
      assert {:ok, speech_act} = Stage.speech_act_description()
      assert_speech_act_match(speech_act, time: :now, speaker: [speaker1, speaker2, speaker3])

      assert cli(~s[replace #{file2}]) == 0
      assert {:ok, speech_act} = Stage.speech_act_description()
      assert_speech_act_match(speech_act, time: :now, speaker: [speaker1, speaker2, speaker3])
    end
  end

  describe "stage command" do
    test "various actions" do
      {graph1, file1} = graph_file([1, 2], type: "nt")
      {_, file2} = graph_file([2, 3], type: "jsonld")
      {_, file3} = graph_file([3, 4], type: "rdf", prefixes: [ex: EX, rdf: RDF])

      refute File.exists?(Stage.default_file())

      assert cli(~s[stage --update #{file1}]) == 0

      assert File.exists?(Stage.default_file())
      assert Stage.changeset() == Changeset.new!(update: graph1)
      assert {:ok, speech_act} = Stage.speech_act_description()
      assert_speech_act_match(speech_act)

      assert cli(~s[stage --replace #{file2} --replace #{file3}]) == 0

      assert Stage.changeset() ==
               Changeset.new!(
                 update: graph([1], prefixes: [ex: EX, rdf: RDF]),
                 replace: graph([2, 3, 4], prefixes: [ex: EX, rdf: RDF])
               )

      assert {:ok, speech_act} = Stage.speech_act_description()
      assert_speech_act_match(speech_act)

      assert cli(~s[stage --add #{file3} --remove #{file1}]) == 0

      assert Stage.changeset() ==
               Changeset.new!(
                 add: graph([3, 4], prefixes: [ex: EX, rdf: RDF]),
                 remove: graph([1, 2], prefixes: [ex: EX, rdf: RDF])
               )
    end

    test "custom stage file" do
      {graph, file} = graph_file([1, 2])
      {_, file2} = graph_file([2, 3])
      {_, file3} = graph_file([3, 4])
      custom_stage_file = "custom_stage_file.jsonld"

      refute File.exists?(custom_stage_file)

      assert cli(~s[stage #{custom_stage_file} --add #{file}]) == 0

      assert File.exists?(custom_stage_file)
      assert Stage.changeset(custom_stage_file) == Changeset.new!(add: graph)
      assert {:ok, speech_act} = Stage.speech_act_description(custom_stage_file)
      assert_speech_act_match(speech_act)

      assert cli(~s[stage #{custom_stage_file} --update #{file2} --update #{file3}]) == 0

      assert Stage.changeset(custom_stage_file) ==
               Changeset.new!(
                 add: graph([1]),
                 update: graph([2, 3, 4])
               )

      assert {:ok, speech_act} = Stage.speech_act_description(custom_stage_file)
      assert_speech_act_match(speech_act)
    end

    test "speech act metadata" do
      {_, file1} = graph_file([1, 2])
      {_, file2} = graph_file([2, 3])
      speaker1 = RDF.iri(EX.Speaker1)
      speaker2 = RDF.iri(EX.Speaker2)
      speaker3 = RDF.iri(EX.Speaker3)

      time = "2015-01-23T23:50:07"
      assert cli(~s[stage --add #{file1} --created-at #{time} --created-by #{speaker1}]) == 0

      assert {:ok, speech_act} = Stage.speech_act_description()
      assert_speech_act_match(speech_act, time: time, speaker: speaker1)

      time = "2015-01-23T23:59:07.123+02:30"

      assert cli(
               ~s[stage --add #{file2} --add #{file1} --created-at #{time} --created-by #{speaker2}]
             ) == 0

      assert {:ok, speech_act} = Stage.speech_act_description()
      assert_speech_act_match(speech_act, time: time, speaker: [speaker1, speaker2])

      time = "2016-01-23T23:50:07"
      assert cli(~s[stage --remove #{file2} --created-at #{time}]) == 0
      assert {:ok, speech_act} = Stage.speech_act_description()
      assert_speech_act_match(speech_act, time: time, speaker: [speaker1, speaker2])

      assert cli(~s[stage --update #{file2} --created-by #{speaker3}]) == 0
      assert {:ok, speech_act} = Stage.speech_act_description()
      assert_speech_act_match(speech_act, time: :now, speaker: [speaker1, speaker2, speaker3])

      assert cli(~s[stage --replace #{file2}]) == 0
      assert {:ok, speech_act} = Stage.speech_act_description()
      assert_speech_act_match(speech_act, time: :now, speaker: [speaker1, speaker2, speaker3])
    end

    test "handling of statements in other graphs" do
      {_, file} = graph_file([1, 2])

      default_graph = graph(:default_graph)
      named_graph = graph(:named_graph) |> Graph.change_name(EX.Graph)

      Changeset.new!(add: statement(1))
      |> Changeset.to_rdf()
      |> Dataset.add(default_graph)
      |> Dataset.add(named_graph)
      |> RDF.write_file(Stage.default_file())

      assert cli(~s[stage --update #{file}]) == 0

      assert {:ok, speech_act} = Stage.speech_act_description()
      assert_speech_act_match(speech_act)

      stage = Stage.load!(Stage.default_file())
      assert Dataset.include?(stage, default_graph)
      assert Dataset.include?(stage, named_graph)
    end

    test "when the stage file is initially empty" do
      {graph, file} = graph_file([1, 2])

      File.touch(Stage.default_file())

      assert cli(~s[stage --update #{file}]) == 0

      assert Stage.changeset() == Changeset.new!(update: graph)
      assert {:ok, speech_act} = Stage.speech_act_description()
      assert_speech_act_match(speech_act)
    end

    test "staging an RDF dataset" do
      graph = graph([1])
      file = "dataset.trig"
      Dataset.new() |> Dataset.add(graph, graph: EX.Graph) |> RDF.write_file!(file)

      assert {1, log} = capture_cli(~s[stage --add #{file}])

      assert log =~
               "Invalid change file #{file}. Named graphs are not supported, yet."

      Dataset.new(graph) |> RDF.write_file!(file, force: true)

      assert cli(~s[stage --add #{file}]) == 0

      assert Stage.changeset() == Changeset.new!(add: graph)
    end
  end

  def assert_speech_act_match(speech_act, predicates \\ []) do
    assert %Description{} = speech_act

    assert {[term_to_iri(Og.SpeechAct)], speech_act} = Description.pop(speech_act, RDF.type())

    assert {speaker, speech_act} = Description.pop(speech_act, Og.speaker())

    assert speaker == predicates |> Keyword.get(:speaker, user_iri()) |> List.wrap()

    assert {[%Literal{literal: %RDF.XSD.DateTime{}} = time], speech_act} =
             Description.pop(speech_act, PROV.endedAtTime())

    if (expected_time = Keyword.get(predicates, :time, :now)) == :now do
      assert DateTime.diff(time.literal.value, XSD.DateTime.now().literal.value, :second) <= 1
    else
      assert time == XSD.datetime(expected_time)
    end

    assert Description.empty?(speech_act)
  end
end
