defmodule Ontogen.CLI.RepositoryCase do
  use ExUnit.CaseTemplate, async: false

  alias Ontogen.Store

  import Ontogen.CLI.TestFactories

  using do
    quote do
      alias Ontogen.CLI
      alias Ontogen.NS.Og

      alias Ontogen.CLI.TestNamespaces.EX
      @compile {:no_warn_undefined, Ontogen.CLI.TestNamespaces.EX}

      import unquote(__MODULE__)
      import Ontogen.CLI.Helper
      import Ontogen.CLI.TestHelper
      import Ontogen.CLI.TestFactories
      import ExUnit.CaptureIO
      import ExUnit.CaptureLog

      setup :clean_repo!

      def clean_repo!(_) do
        cwd = File.cwd!()
        tmp_dir = cd_tmp_dir!()

        on_exit(fn ->
          Ontogen.Config.store() |> Store.drop(:all)
          File.cd!(cwd)
        end)

        {0, _} =
          with_io(fn ->
            CLI.main(
              ~w[init http://example.repo.com/ --dataset http://example.repo.com/dataset --prov-graph http://example.repo.com/prov] ++
                ~w[--query-url http://localhost:7879/query --update-url http://localhost:7879/update --graph-store-url http://localhost:7879/store]
            )
          end)

        [dir: tmp_dir]
      end
    end
  end

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
