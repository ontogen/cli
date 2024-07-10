defmodule Ontogen.CLI.RepositoryCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use Ontogen.CLI.Case, async: false

      import unquote(__MODULE__)

      setup :clean_repository
    end
  end

  import Ontogen.CLI.TestHelper
  alias Ontogen.Operations.CleanCommand

  def clean_repository(context) do
    boot_opts = (context[:boot_opts] || []) |> Keyword.put(:log, false)

    start_supervised({Ontogen, boot_opts})

    if Map.get(context, :setup, true) do
      {0, _} = capture_cli(~s[setup])
    end

    if Map.get(context, :clean_dataset, true) do
      # We can not use Ontogen.clean_dataset!() here because `on_exit` runs in a
      # separate process after the test process has terminated. This means the
      # Ontogen GenServer started above with `start_supervised` is no longer.
      on_exit(fn ->
        with {:ok, service} <- Ontogen.Config.service() do
          case CleanCommand.call(service, :all) do
            {:ok, _service} -> :ok
            {:error, _} = error -> raise error
          end
        end
      end)
    end

    :ok
  end
end
