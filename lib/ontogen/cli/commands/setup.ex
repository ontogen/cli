defmodule Ontogen.CLI.Commands.Setup do
  use Ontogen.CLI.Command,
    name: :setup,
    about: "Install the Ontogen repository on the configured store",
    args: [],
    options: []

  @impl true
  def handle_call(%{}, _options, _flags, []) do
    with {:ok, _service} <- Ontogen.setup() do
      success("Set up Ontogen repository")
    end
  end
end
