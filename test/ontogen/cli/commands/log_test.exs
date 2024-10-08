defmodule Ontogen.CLI.Commands.LogTest do
  use Ontogen.CLI.RepositoryCase, async: false

  doctest Ontogen.CLI.Commands.Log

  import Ontogen.IdUtils

  test "with empty repository" do
    assert {1, log} = capture_cli(~s[log])

    assert log =~ "Repository #{Ontogen.repository!().__id__} does not have any commits yet"
  end

  test "default format" do
    [third, second, first] = init_history()

    colored_output =
      ~r"""
      \e\[33m#{short_hash_from_iri(third.__id__)}\e\[0m - Third commit \e\[32m\(\d+ .+\)\e\[0m \e\[1m\e\[34m<Jane Doe jane\.doe@example\.com>\e\[0m
      \e\[33m#{short_hash_from_iri(second.__id__)}\e\[0m - Second commit \e\[32m\(\d+ .+\)\e\[0m \e\[1m\e\[34m<Jane Doe jane\.doe@example\.com>\e\[0m
      \e\[33m#{short_hash_from_iri(first.__id__)}\e\[0m - Initial commit \e\[32m\(\d+ .+\)\e\[0m \e\[1m\e\[34m<Jane Doe jane\.doe@example\.com>\e\[0m
      """m

    assert {0, log} = capture_cli(~s[log])

    assert log =~ colored_output

    assert {0, log} = capture_cli(~s[log --color])

    assert log =~ colored_output

    assert {0, log} = capture_cli(~s[log --no-color])

    assert log =~ ~r"""
           #{short_hash_from_iri(third.__id__)} - Third commit \(\d+ .+\) <Jane Doe jane\.doe@example\.com>
           #{short_hash_from_iri(second.__id__)} - Second commit \(\d+ .+\) <Jane Doe jane\.doe@example\.com>
           #{short_hash_from_iri(first.__id__)} - Initial commit \(\d+ .+\) <Jane Doe jane\.doe@example\.com>
           """m
  end

  test "format option" do
    [third, second, first] = init_history()

    assert {0, log} = capture_cli(~s[log --format raw])

    assert log ==
             """
             \e[33mcommit #{hash_from_iri(third.__id__)}\e[0m
             parent #{hash_from_iri(second.__id__)}
             update 7060ebefffd8f8b899c7c44703878b5b32ae833efc7602050782c5eae86c4887
             committer <#{Ontogen.Config.agent_id()}> 1685106117 +0000

             Third commit

             \e[33mcommit #{hash_from_iri(second.__id__)}\e[0m
             parent #{hash_from_iri(first.__id__)}
             add f0631b99ac7b6fb265b68867106f9493154543db0d1b8ccadc820b14a6a9dd2c
             remove 979ebda022992a4e5d65edddb1087b9eac54b71e688c34e69c3a99ac25bfa52e
             committer <#{Ontogen.Config.agent_id()}> 1685106119 +0000

             Second commit

             \e[33mcommit #{hash_from_iri(first.__id__)}\e[0m
             add 979ebda022992a4e5d65edddb1087b9eac54b71e688c34e69c3a99ac25bfa52e
             committer <#{Ontogen.Config.agent_id()}> 1685106121 +0000

             Initial commit
             """
  end

  test "range specs" do
    [third, second, first] = init_history()

    assert {0, log} =
             capture_cli(~s[log --no-color --format oneline #{hash_from_iri(first.__id__)}..head])

    assert log ==
             """
             #{hash_from_iri(third.__id__)} Third commit
             #{hash_from_iri(second.__id__)} Second commit
             """

    assert {0, log} =
             capture_cli(
               ~s[log --no-color --format oneline #{hash_from_iri(second.__id__)}~1..head~1]
             )

    assert log ==
             """
             #{hash_from_iri(second.__id__)} Second commit
             """
  end

  test "resource filter" do
    [_third, second, _first] = init_history()

    assert {0, log} = capture_cli(~s[log --no-color --format oneline --resource #{EX.s2()}])

    assert log ==
             """
             #{hash_from_iri(second.__id__)} Second commit
             """
  end

  test "changeset format flags" do
    [third, second, first] = init_history()

    assert {0, log} = capture_cli(~s[log --format short --no-color --stat])

    assert log ==
             """
             commit #{hash_from_iri(third.__id__)}
             Author: Jane Doe <jane.doe@example.com>

             Third commit

              http://example.com/s3 | 1 +
              http://example.com/s4 | 1 +
              2 resources changed, 2 insertions(+)

             commit #{hash_from_iri(second.__id__)}
             Author: Jane Doe <jane.doe@example.com>

             Second commit

              http://example.com/s1 | 1 -
              http://example.com/s2 | 1 +
              2 resources changed, 1 insertions(+), 1 deletions(-)

             commit #{hash_from_iri(first.__id__)}
             Author: Jane Doe <jane.doe@example.com>

             Initial commit

              http://example.com/s1 | 1 +
              1 resources changed, 1 insertions(+)
             """

    assert {0, log} =
             capture_cli(
               ~s[log --format medium --no-color --resource-only --shortstat --hash-format short]
             )

    assert log ==
             """
             commit #{short_hash_from_iri(third.__id__)}
             Author: Jane Doe <jane.doe@example.com>
             Date:   Fri May 26 13:02:00 2023 +0000

             Third commit

             http://example.com/s3
             http://example.com/s4

              2 resources changed, 2 insertions(+)

             commit #{short_hash_from_iri(second.__id__)}
             Author: Jane Doe <jane.doe@example.com>
             Date:   Fri May 26 13:01:58 2023 +0000

             Second commit

             http://example.com/s1
             http://example.com/s2

              2 resources changed, 1 insertions(+), 1 deletions(-)

             commit #{short_hash_from_iri(first.__id__)}
             Author: Jane Doe <jane.doe@example.com>
             Date:   Fri May 26 13:02:01 2023 +0000

             Initial commit

             http://example.com/s1

              1 resources changed, 1 insertions(+)
             """

    assert {0, log} = capture_cli(~s[log --no-color --changes --format oneline])

    assert log ==
             """
             #{hash_from_iri(third.__id__)} Third commit
             #  <http://example.com/s2>
             #±     <http://example.com/p2> <http://example.com/o2> .

                <http://example.com/s3>
              ±     <http://example.com/p3> <http://example.com/o3> .

                <http://example.com/s4>
              ±     <http://example.com/p4> <http://example.com/o4> .


             #{hash_from_iri(second.__id__)} Second commit
                <http://example.com/s1>
              -     <http://example.com/p1> <http://example.com/o1> .

                <http://example.com/s2>
              +     <http://example.com/p2> <http://example.com/o2> .


             #{hash_from_iri(first.__id__)} Initial commit
                <http://example.com/s1>
              +     <http://example.com/p1> <http://example.com/o1> .

             """

    assert {0, log} =
             capture_cli(~s[log --no-color --format short --speech-changes --commit-changes])

    assert log ==
             """
             commit #{hash_from_iri(third.__id__)}
             Author: Jane Doe <jane.doe@example.com>

             Third commit

               <http://example.com/s2>
             ±     <http://example.com/p2> <http://example.com/o2> .

               <http://example.com/s3>
             ±     <http://example.com/p3> <http://example.com/o3> .

               <http://example.com/s4>
             ±     <http://example.com/p4> <http://example.com/o4> .


               <http://example.com/s3>
             ±     <http://example.com/p3> <http://example.com/o3> .

               <http://example.com/s4>
             ±     <http://example.com/p4> <http://example.com/o4> .


             commit #{hash_from_iri(second.__id__)}
             Author: Jane Doe <jane.doe@example.com>

             Second commit

               <http://example.com/s1>
             -     <http://example.com/p1> <http://example.com/o1> .

               <http://example.com/s2>
             +     <http://example.com/p2> <http://example.com/o2> .


               <http://example.com/s1>
             -     <http://example.com/p1> <http://example.com/o1> .

               <http://example.com/s2>
             +     <http://example.com/p2> <http://example.com/o2> .


             commit #{hash_from_iri(first.__id__)}
             Author: Jane Doe <jane.doe@example.com>

             Initial commit

               <http://example.com/s1>
             +     <http://example.com/p1> <http://example.com/o1> .


               <http://example.com/s1>
             +     <http://example.com/p1> <http://example.com/o1> .

             """
  end

  test "order flags" do
    [third, second, first] = init_history()

    assert {0, log} = capture_cli(~s[log --no-color --format oneline --reverse])

    assert log ==
             """
             #{hash_from_iri(first.__id__)} Initial commit
             #{hash_from_iri(second.__id__)} Second commit
             #{hash_from_iri(third.__id__)} Third commit
             """

    assert {0, log} = capture_cli(~s[log --no-color --format oneline --date-order])

    assert log ==
             """
             #{hash_from_iri(first.__id__)} Initial commit
             #{hash_from_iri(second.__id__)} Second commit
             #{hash_from_iri(third.__id__)} Third commit
             """

    assert {0, log} = capture_cli(~s[log --no-color --format oneline --date-order --reverse])

    assert log ==
             """
             #{hash_from_iri(third.__id__)} Third commit
             #{hash_from_iri(second.__id__)} Second commit
             #{hash_from_iri(first.__id__)} Initial commit
             """

    assert {0, log} =
             capture_cli(~s[log --no-color --format oneline --author-date-order --reverse])

    assert log ==
             """
             #{hash_from_iri(second.__id__)} Second commit
             #{hash_from_iri(third.__id__)} Third commit
             #{hash_from_iri(first.__id__)} Initial commit
             """
  end

  test "invalid option combinations" do
    assert {1, log} = capture_cli(~s[log --color --no-color])

    assert log =~ "both flags --color and --no-color set"

    assert {1, log} = capture_cli(~s[log --date-order --author-date-order --format oneline])

    assert log =~ "both flags --date-order and --author-date-order set"
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
