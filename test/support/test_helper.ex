defmodule Ontogen.CLI.TestHelper do
  import ExUnit.Assertions

  import ExUnit.CaptureLog

  def configless_ontogen(_) do
    capture_log(fn -> Application.stop(:ontogen) end)
    :ok = Application.start(:ontogen)
    refute Ontogen.CLI.Helper.config_available?()
    :ok
  end

  def tmp_dir! do
    Briefly.create!(type: :directory)
  end

  def cd_tmp_dir! do
    tap(tmp_dir!(), &File.cd!/1)
  end
end
