defmodule Ontogen.CLI.TestFixtures do
  @moduledoc """
  Test fixtures.
  """

  import ExUnit.Assertions
  import Ontogen.CLI.TestFactories

  def init_commit_history(history) when is_list(history) do
    start_offset = Enum.count(history)
    time = datetime()

    history
    |> Enum.with_index(&{&1, start_offset - &2})
    |> Enum.map(fn {commit_args, time_offset} ->
      commit_args =
        Keyword.put_new(commit_args, :time, DateTime.add(time, 0 - time_offset, :hour))

      assert {:ok, commit} = Ontogen.commit(commit_args)
      assert Ontogen.head() == commit

      commit
    end)
    |> Enum.reverse()
  end
end
