defmodule Ontogen.CLI.TestHelper do
  import ExUnit.CaptureIO

  @test_config_path Path.absname("test/data/config")
  def test_config_path, do: @test_config_path

  def capture_cli(args) do
    with_io(fn -> cli(args) end)
  end

  def cli(args) when is_binary(args) do
    args
    |> OptionParser.split()
    |> Ontogen.CLI.main()
  end
end
