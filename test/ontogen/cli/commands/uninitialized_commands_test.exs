defmodule Ontogen.CLI.Commands.UninitializedCommandsTest do
  use Ontogen.CLI.Case, async: false

  @moduletag init: false

  @repo_access_error "\e[31mUnable to access repository. In case you haven't created one yet, run: \e[1m\e[32m\e[3mog init\e[0m\e[0m.\n\e[0m\e[0m\n"

  describe "booted Ontogen service GenServer without initialized repository" do
    setup context do
      boot_opts = (context[:boot_opts] || []) |> Keyword.put(:log, false)
      start_supervised({Ontogen, boot_opts})
      :ok
    end

    test "status", %{tmp_dir: _dir} do
      assert {1, log} = capture_cli(~s[status])

      assert log =~ @repo_access_error
    end

    test "log", %{tmp_dir: _dir} do
      assert {1, log} = capture_cli(~s[log])

      assert log =~ @repo_access_error
    end

    test "changeset", %{tmp_dir: _dir} do
      assert {1, log} = capture_cli(~s[changeset HEAD~1])

      assert log =~ @repo_access_error
    end

    test "commit", %{tmp_dir: _dir} do
      assert {1, log} = capture_cli(~s[commit -m "test commit"])

      assert log =~ @repo_access_error
    end

    test "revert", %{tmp_dir: _dir} do
      assert {1, log} = capture_cli(~s[revert HEAD])

      assert log =~ @repo_access_error
    end
  end
end
