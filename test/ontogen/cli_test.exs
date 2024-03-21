defmodule Ontogen.CLITest do
  use ExUnit.Case
  doctest Ontogen.CLI

  test "greets the world" do
    assert Ontogen.CLI.hello() == :world
  end
end
