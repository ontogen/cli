defmodule Ontogen.CLI.TestHelper do
  import ExUnit.Assertions

  import ExUnit.CaptureLog
  import ExUnit.CaptureIO

  def configless_ontogen(_) do
    capture_log(fn -> Application.stop(:ontogen) end)
    :ok = Application.start(:ontogen)
    refute Ontogen.CLI.Helper.config_available?()
    :ok
  end

  def capture_cli(args) do
    with_io(fn -> cli(args) end)
  end

  def cli(args) when is_binary(args) do
    args
    |> OptionParser.split()
    |> Ontogen.CLI.main()
  end

  def tmp_dir! do
    Briefly.create!(type: :directory)
  end

  def cd_tmp_dir! do
    tap(tmp_dir!(), &File.cd!/1)
  end
end
