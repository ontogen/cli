defmodule Ontogen.CLI.Case do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias Ontogen.{Service, Store, Repository, Dataset, CLI, Bog}
      alias Ontogen.NS.Og

      alias Ontogen.CLI.TestNamespaces.EX
      @compile {:no_warn_undefined, Ontogen.CLI.TestNamespaces.EX}

      import unquote(__MODULE__)
      import Ontogen.CLI.TestFactories
      import Ontogen.CLI.TestFixtures
      import Ontogen.CLI.TestHelper
      import Ontogen.CLI.Helper

      import unquote(__MODULE__)

      @moduletag :tmp_dir

      setup context do
        cwd = File.cwd!()
        tmp_dir = context.tmp_dir
        File.cd!(tmp_dir)

        on_exit(fn ->
          File.cd!(cwd)
          File.rm_rf!(tmp_dir)
        end)
      end

      setup :init_config
    end
  end

  import Ontogen.CLI.TestHelper

  def init_config(context) do
    if init_opts = Map.get(context, :init, "--template #{test_config_path()}") do
      {0, _} = capture_cli(~s[init #{init_opts}])
    end

    :ok
  end
end
