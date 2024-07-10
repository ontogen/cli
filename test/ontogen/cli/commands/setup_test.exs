defmodule Ontogen.CLI.Commands.SetupTest do
  use Ontogen.CLI.RepositoryCase, async: false

  doctest Ontogen.CLI.Commands.Setup

  @moduletag setup: false

  @tag clean_dataset: false
  test "without arguments" do
    assert Ontogen.status() == :not_setup

    assert {0, log} = capture_cli(~s[setup])

    assert log =~ "Set up Ontogen repository"

    assert Ontogen.status() == :ready
  end
end
