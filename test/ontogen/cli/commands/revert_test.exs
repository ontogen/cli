defmodule Ontogen.CLI.Commands.RevertTest do
  use Ontogen.CLI.RepositoryCase, async: false

  doctest Ontogen.CLI.Commands.Revert

  alias Ontogen.Commit

  test "with empty repository" do
    assert {1, log} = capture_cli(~s[revert HEAD])

    assert log =~ "Repository #{Ontogen.repository!().__id__} does not have any commits yet"
  end

  test "last commit with defaults" do
    [third, second, _first] = history = init_history()

    message = "Revert of commits:"

    refute File.exists?(Ontogen.CLI.Stage.default_file())

    assert {0, log} = capture_cli(~s[revert HEAD])

    refute File.exists?(Ontogen.CLI.Stage.default_file())

    assert {:ok, [%Ontogen.Commit{} = revert | ^history]} = Ontogen.log()

    assert DateTime.diff(revert.time, DateTime.utc_now(), :second) <= 1
    assert revert.committer == Ontogen.Config.user!()
    assert revert.message =~ message

    refute revert.speech_act
    assert revert.reverted_base_commit == second.__id__
    assert revert.reverted_target_commit == third.__id__

    assert log =~ "[#{Ontogen.IdUtils.to_hash(revert)}] #{message}"
    assert log =~ "0 insertions, 2 deletions, 0 overwrites"
  end

  test "commit range with custom metadata" do
    [_third, second, _first] = history = init_history()

    message = "Custom revert commit message"

    assert {0, log} =
             capture_cli(
               ~s[revert HEAD~3..HEAD~1 --message "#{message}"  --committed-by #{id(:agent)} --committed-at #{DateTime.to_iso8601(datetime())}]
             )

    assert {:ok, [%Ontogen.Commit{} = revert | ^history]} = Ontogen.log()

    assert revert.time == datetime()
    assert revert.committer == id(:agent)
    assert revert.message == message

    refute revert.speech_act
    assert revert.reverted_base_commit == Commit.root()
    assert revert.reverted_target_commit == second.__id__

    assert log =~ "[#{Ontogen.IdUtils.to_hash(revert)}] #{message}"
    assert log =~ "0 insertions, 1 deletions, 0 overwrites"
  end

  test "no effective changes" do
    history = init_history()

    assert {1, log} = capture_cli(~s[revert HEAD~3..HEAD~2])
    assert log =~ "No effective changes."

    assert {:ok, ^history} = Ontogen.log()
  end

  test "bad range" do
    init_history()
    assert {1, log} = capture_cli(~s[revert HEAD~4..HEAD~2])

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
