defmodule Ontogen.CLI.NoRepositoryError do
  @moduledoc """
  Raised when a command is called without a `.ontogen` directory for the repository.
  """
  defexception [:current_path, :reason]

  def message(%{reason: nil} = _) do
    """
    Unable to access repository. In case you haven't created one yet, run: #{IO.ANSI.format([:bright, :green, :italic, "og init", :reset])}.
    """
  end

  def message(%{reason: reason} = _) do
    """
    Unable to access repository due to: #{inspect(reason)}
    """
  end
end
