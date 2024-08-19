defmodule Ontogen.CLI.Command do
  @moduledoc """
  Behaviour for the Ontogen CLI commands.

  The result integer or `:abort` is passed to `System.halt/1`.
  """
  @callback handle_call(args :: map, options :: map, flags :: map, unknown :: list(binary)) ::
              :ok | {:ok, non_neg_integer()} | {:error, binary} | :abort

  defmacro __using__(command_spec) do
    name = Keyword.fetch!(command_spec, :name)
    command_spec = Keyword.update!(command_spec, :name, &to_string/1)

    quote do
      @behaviour unquote(__MODULE__)

      import Ontogen.CLI.Helper

      @name unquote(name)
      def name, do: @name

      def command_spec, do: unquote(command_spec)

      def call(args, options, flags, unknown) do
        with :ok <- ensure_repository_exists!() do
          handle_call(args, options, flags, unknown)
        end
      end

      defoverridable call: 4
    end
  end
end
