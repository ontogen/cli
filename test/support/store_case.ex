defmodule Ontogen.CLI.StoreCase do
  use ExUnit.CaseTemplate

  alias Ontogen.Store

  using do
    quote do
      alias Ontogen.Store

      import unquote(__MODULE__)
      import Ontogen.CLI.TestHelper

      setup do
        on_exit(fn -> clean_store!() end)
      end
    end
  end

  import Ontogen.CLI.Helper

  def clean_store!(_ \\ nil) do
    if config_available?() do
      Ontogen.Config.store() |> Store.drop(:all)
    end
  end
end
