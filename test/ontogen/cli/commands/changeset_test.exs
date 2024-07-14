defmodule Ontogen.CLI.Commands.ChangesetTest do
  use Ontogen.CLI.RepositoryCase, async: false

  doctest Ontogen.CLI.Commands.Changeset

  test "with empty repository" do
    assert {1, log} = capture_cli(~s[changeset HEAD~1])

    assert log =~ "Repository #{Ontogen.repository!().__id__} does not have any commits yet"
  end

  test "single commit ref" do
    init_history()

    assert {0, log} = capture_cli(~s[changeset HEAD])

    assert log ==
             """
             \e[0m  <http://example.com/s3>
             \e[36m±     <http://example.com/p3> <http://example.com/o3> .

             \e[0m  <http://example.com/s4>
             \e[36m±     <http://example.com/p4> <http://example.com/o4> .
             \e[0m
             """
  end

  test "commit range" do
    [_third, second, _first] = init_history()

    assert {0, log} = capture_cli(~s[changeset HEAD~3..#{second.__id__} --no-color])

    assert log ==
             """
               <http://example.com/s2>
             +     <http://example.com/p2> <http://example.com/o2> .

             """
  end

  test "resource-specific" do
    init_history()

    assert {0, log} =
             capture_cli(~s[changeset HEAD~3..head --resource http://example.com/s3 --no-color])

    assert log ==
             """
               <http://example.com/s3>
             ±     <http://example.com/p3> <http://example.com/o3> .

             """
  end

  test "changeset format flags" do
    init_history()

    assert {0, log} = capture_cli(~s[changeset HEAD~3..head --no-color --stat])

    assert log ==
             """
              http://example.com/s2 | 1 +
              http://example.com/s3 | 1 +
              http://example.com/s4 | 1 +
              3 resources changed, 3 insertions(+)
             """

    assert {0, log} =
             capture_cli(~s[changeset HEAD~2..head --resource-only --shortstat --no-color])

    assert log ==
             """
             http://example.com/s1
             http://example.com/s2
             http://example.com/s3
             http://example.com/s4
              4 resources changed, 3 insertions(+), 1 deletions(-)
             """

    assert {0, log} =
             capture_cli(~s[changeset HEAD~3..HEAD~1 --changes --shortstat --no-color])

    assert log ==
             """
               <http://example.com/s2>
             +     <http://example.com/p2> <http://example.com/o2> .

              1 resources changed, 1 insertions(+)
             """
  end

  test "no effective changes" do
    init_commit_history([
      [
        speech_act: [add: graph(1)]
      ],
      [
        speech_act: [
          add: graph(2),
          remove: graph(1)
        ]
      ],
      [
        speech_act: [remove: graph([2])]
      ]
    ])

    assert {0, log} = capture_cli(~s[changeset HEAD~3..HEAD])

    assert log == """
           No changes.
           """
  end

  test "bad range" do
    init_history()
    assert {1, log} = capture_cli(~s[changeset HEAD~4..HEAD~2])

    assert log =~ "Invalid commit range: out of range"
  end

  defp init_history do
    init_commit_history([
      [
        speech_act: [
          add: graph(1),
          time: datetime(-1)
        ],
        message: "Initial commit",
        time: datetime(-1)
      ],
      [
        speech_act: [
          add: graph(2),
          remove: graph(1),
          time: datetime(-4)
        ],
        message: "Second commit",
        time: datetime(-3)
      ],
      [
        speech_act: [
          update: graph([2, 3, 4]),
          time: datetime(-2)
        ],
        message: "Third commit",
        time: datetime(-5)
      ]
    ])
  end
end
