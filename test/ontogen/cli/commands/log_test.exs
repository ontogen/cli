defmodule Ontogen.CLI.Commands.LogTest do
  use Ontogen.CLI.RepositoryCase, async: false

  doctest Ontogen.CLI.Commands.Log

  import Ontogen.IdUtils

  test "default format" do
    init_history()

    colored_output =
      ~r"""
      \e\[33m478eaac96b\e\[0m - Third commit \e\[32m\(\d+ .+\)\e\[0m \e\[1m\e\[34m<John Doe john\.doe@example\.com>\e\[0m
      \e\[33mc268c4c752\e\[0m - Second commit \e\[32m\(\d+ .+\)\e\[0m \e\[1m\e\[34m<John Doe john\.doe@example\.com>\e\[0m
      \e\[33m4dba63ae4e\e\[0m - Initial commit \e\[32m\(\d+ .+\)\e\[0m \e\[1m\e\[34m<John Doe john\.doe@example\.com>\e\[0m
      """m

    assert {0, log} =
             with_io(fn ->
               CLI.main(~w[log])
             end)

    assert log =~ colored_output

    assert {0, log} =
             with_io(fn ->
               CLI.main(~w[log --color])
             end)

    assert log =~ colored_output

    assert {0, log} =
             with_io(fn ->
               CLI.main(~w[log --no-color])
             end)

    assert log =~ ~r"""
           478eaac96b - Third commit \(\d+ .+\) <John Doe john\.doe@example\.com>
           c268c4c752 - Second commit \(\d+ .+\) <John Doe john\.doe@example\.com>
           4dba63ae4e - Initial commit \(\d+ .+\) <John Doe john\.doe@example\.com>
           """m
  end

  test "format option" do
    [third, second, first] = init_history()

    assert {0, log} =
             with_io(fn ->
               CLI.main(~w[log --format raw])
             end)

    assert log ==
             """
             \e[33mcommit #{hash_from_iri(third.__id__)}\e[0m
             parent c268c4c7523f03710d3b2a9ca9522d8f67cf180aedb1b885abf0454c7b29581f
             update 7060ebefffd8f8b899c7c44703878b5b32ae833efc7602050782c5eae86c4887
             committer <http://example.com/Agent/john_doe> 1685106117 +0000

             Third commit

             \e[33mcommit #{hash_from_iri(second.__id__)}\e[0m
             parent 4dba63ae4ec4ee74a58eecab21157b84263efe00518ff443730b21856d949804
             add f0631b99ac7b6fb265b68867106f9493154543db0d1b8ccadc820b14a6a9dd2c
             remove 979ebda022992a4e5d65edddb1087b9eac54b71e688c34e69c3a99ac25bfa52e
             committer <http://example.com/Agent/john_doe> 1685106119 +0000

             Second commit

             \e[33mcommit #{hash_from_iri(first.__id__)}\e[0m
             add 979ebda022992a4e5d65edddb1087b9eac54b71e688c34e69c3a99ac25bfa52e
             committer <http://example.com/Agent/john_doe> 1685106121 +0000

             Initial commit
             """
  end

  test "range specs" do
    [third, second, first] = init_history()

    assert {0, log} =
             with_io(fn ->
               CLI.main(~w[log --no-color --format oneline #{hash_from_iri(first.__id__)}..head])
             end)

    assert log ==
             """
             #{hash_from_iri(third.__id__)} Third commit
             #{hash_from_iri(second.__id__)} Second commit
             """

    assert {0, log} =
             with_io(fn ->
               CLI.main(
                 ~w[log --no-color --format oneline #{hash_from_iri(second.__id__)}~1..head~1]
               )
             end)

    assert log ==
             """
             #{hash_from_iri(second.__id__)} Second commit
             """
  end

  test "resource filter" do
    [_third, second, _first] = init_history()

    assert {0, log} =
             with_io(fn ->
               CLI.main(~w[log --no-color --format oneline --resource #{EX.s2()}])
             end)

    assert log ==
             """
             #{hash_from_iri(second.__id__)} Second commit
             """
  end

  test "changeset format flags" do
    [third, second, first] = init_history()

    assert {0, log} =
             with_io(fn ->
               CLI.main(~w[log --format short --no-color --stat])
             end)

    assert log ==
             """
             commit 478eaac96be6bcd4c1ba1016403356214ef799960fc3918636291ea1d78b56ac
             Author: John Doe <john.doe@example.com>

             Third commit

              http://example.com/s3 | 1 +
              http://example.com/s4 | 1 +
              2 resources changed, 2 insertions(+)

             commit c268c4c7523f03710d3b2a9ca9522d8f67cf180aedb1b885abf0454c7b29581f
             Author: John Doe <john.doe@example.com>

             Second commit

              http://example.com/s1 | 1 -
              http://example.com/s2 | 1 +
              2 resources changed, 1 insertions(+), 1 deletions(-)

             commit 4dba63ae4ec4ee74a58eecab21157b84263efe00518ff443730b21856d949804
             Author: John Doe <john.doe@example.com>

             Initial commit

              http://example.com/s1 | 1 +
              1 resources changed, 1 insertions(+)
             """

    assert {0, log} =
             with_io(fn ->
               CLI.main(~w[log --format medium --no-color --resource-only --shortstat])
             end)

    assert log ==
             """
             commit 478eaac96be6bcd4c1ba1016403356214ef799960fc3918636291ea1d78b56ac
             Author: John Doe <john.doe@example.com>
             Date:   Fri May 26 13:02:00 2023 +0000

             Third commit

             http://example.com/s3
             http://example.com/s4

              2 resources changed, 2 insertions(+)

             commit c268c4c7523f03710d3b2a9ca9522d8f67cf180aedb1b885abf0454c7b29581f
             Author: John Doe <john.doe@example.com>
             Date:   Fri May 26 13:01:58 2023 +0000

             Second commit

             http://example.com/s1
             http://example.com/s2

              2 resources changed, 1 insertions(+), 1 deletions(-)

             commit 4dba63ae4ec4ee74a58eecab21157b84263efe00518ff443730b21856d949804
             Author: John Doe <john.doe@example.com>
             Date:   Fri May 26 13:02:01 2023 +0000

             Initial commit

             http://example.com/s1

              1 resources changed, 1 insertions(+)
             """

    assert {0, log} =
             with_io(fn ->
               CLI.main(~w[log --no-color --changes --format oneline])
             end)

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
             with_io(fn ->
               CLI.main(~w[log --no-color --format short --speech-changes --effective-changes])
             end)

    assert log ==
             """
             commit 478eaac96be6bcd4c1ba1016403356214ef799960fc3918636291ea1d78b56ac
             Author: John Doe <john.doe@example.com>

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


             commit c268c4c7523f03710d3b2a9ca9522d8f67cf180aedb1b885abf0454c7b29581f
             Author: John Doe <john.doe@example.com>

             Second commit

               <http://example.com/s1>
             -     <http://example.com/p1> <http://example.com/o1> .

               <http://example.com/s2>
             +     <http://example.com/p2> <http://example.com/o2> .


               <http://example.com/s1>
             -     <http://example.com/p1> <http://example.com/o1> .

               <http://example.com/s2>
             +     <http://example.com/p2> <http://example.com/o2> .


             commit 4dba63ae4ec4ee74a58eecab21157b84263efe00518ff443730b21856d949804
             Author: John Doe <john.doe@example.com>

             Initial commit

               <http://example.com/s1>
             +     <http://example.com/p1> <http://example.com/o1> .


               <http://example.com/s1>
             +     <http://example.com/p1> <http://example.com/o1> .

             """
  end

  test "order flags" do
    [third, second, first] = init_history()

    assert {0, log} =
             with_io(fn ->
               CLI.main(~w[log --no-color --format oneline --reverse])
             end)

    assert log ==
             """
             #{hash_from_iri(first.__id__)} Initial commit
             #{hash_from_iri(second.__id__)} Second commit
             #{hash_from_iri(third.__id__)} Third commit
             """

    assert {0, log} =
             with_io(fn ->
               CLI.main(~w[log --no-color --format oneline --date-order])
             end)

    assert log ==
             """
             #{hash_from_iri(first.__id__)} Initial commit
             #{hash_from_iri(second.__id__)} Second commit
             #{hash_from_iri(third.__id__)} Third commit
             """

    assert {0, log} =
             with_io(fn ->
               CLI.main(~w[log --no-color --format oneline --date-order --reverse])
             end)

    assert log ==
             """
             #{hash_from_iri(third.__id__)} Third commit
             #{hash_from_iri(second.__id__)} Second commit
             #{hash_from_iri(first.__id__)} Initial commit
             """

    assert {0, log} =
             with_io(fn ->
               CLI.main(~w[log --no-color --format oneline --author-date-order --reverse])
             end)

    assert log ==
             """
             #{hash_from_iri(second.__id__)} Second commit
             #{hash_from_iri(third.__id__)} Third commit
             #{hash_from_iri(first.__id__)} Initial commit
             """
  end

  test "invalid option combinations" do
    assert {1, log} =
             with_io(fn ->
               CLI.main(~w[log --color --no-color])
             end)

    assert log =~ "both flags --color and --no-color set"

    assert {1, log} =
             with_io(fn ->
               CLI.main(~w[log --date-order --author-date-order --format oneline])
             end)

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
