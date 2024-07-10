defmodule Ontogen.CLI.Commands.StatusTest do
  use Ontogen.CLI.RepositoryCase, async: false

  doctest Ontogen.CLI.Commands.Status

  alias Ontogen.CLI.Stage

  test "returns combined changes with the latest revision" do
    {_graph, file1} = graph_file([1, 2, {2, 1}])
    {_graph, file2} = graph_file([2, {2, 3}, 3])

    assert {0, _} = capture_cli(~s[commit --add #{file1} --message "Initial commit"])

    assert cli(
             ~s[add #{file2} --created-by #{id(:agent)} --created-at #{DateTime.to_iso8601(datetime())}]
           ) == 0

    assert File.exists?(Stage.default_file())

    assert {0, log} = capture_cli(~s[status --no-color])

    assert log ==
             """
             speech_act f62cb6ec3b9a9ebf7a94f3cfe51155332921abeb030ae97917f47f9a0516732d
             Source: -
             Author: <http://example.com/Agent>
             Date:   Fri May 26 13:02:02 2023 +0000

                <http://example.com/s2>
                    <http://example.com/p1> <http://example.com/o1> ;
             #+     <http://example.com/p2> <http://example.com/o2> ;
              +     <http://example.com/p3> <http://example.com/o3> .

                <http://example.com/s3>
              +     <http://example.com/p3> <http://example.com/o3> .

             """

    assert {0, log} = capture_cli(~s[status --no-color --hash-format short])

    assert log ==
             """
             speech_act f62cb6ec3b
             Source: -
             Author: <http://example.com/Agent>
             Date:   Fri May 26 13:02:02 2023 +0000

                <http://example.com/s2>
                    <http://example.com/p1> <http://example.com/o1> ;
             #+     <http://example.com/p2> <http://example.com/o2> ;
              +     <http://example.com/p3> <http://example.com/o3> .

                <http://example.com/s3>
              +     <http://example.com/p3> <http://example.com/o3> .

             """
  end

  test "invalid option combinations" do
    assert {1, log} = capture_cli(~s[status --color --no-color])

    assert log =~ "both flags --color and --no-color set"
  end

  test "with empty repository" do
    {_graph, file} = graph_file([1])

    assert cli(
             ~s[add #{file} --created-at #{DateTime.to_iso8601(datetime())} --created-by #{id(:agent)}]
           ) == 0

    assert {0, log} = capture_cli(~s[status --no-color])

    assert log =~
             """
             speech_act 1e7e3365f92f6c15929c7f6ebe33cf3d4210bb1bd7515f4df64f1bc6dd3494b4
             Source: -
             Author: <#{id(:agent)}>
             Date:   Fri May 26 13:02:02 2023 +0000

                <http://example.com/s1>
              +     <http://example.com/p1> <http://example.com/o1> .

             """
  end

  test "no stage file" do
    assert {1, log} = capture_cli(~s[status])

    assert log =~ "no stage file found"
  end

  test "empty changeset" do
    File.touch(Stage.default_file())

    assert {1, log} = capture_cli(~s[status])

    assert log =~ "empty stage"
  end

  test "no effective changes" do
    {_graph, file} = graph_file([1, 2])

    assert cli(~s[add #{file}]) == 0
    assert {0, _} = capture_cli(~s[commit --message Commit1])
    assert cli(~s[add #{file}]) == 0

    assert {0, log} = capture_cli(~s[status])
    assert log =~ "No effective changes."
  end
end
