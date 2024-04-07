defmodule Ontogen.CLI.Action do
  alias Ontogen.CLI.Helper
  alias RDF.XSD

  @actions [
             add: "RDF file with data to be added",
             update: "RDF file with data to be updated",
             replace: "RDF file with data to be replaced",
             remove: "RDF file with data to be removed"
           ]
           |> Enum.map(fn {name, help} ->
             {name,
              [
                value_name: "FILE",
                long: "--#{name}",
                help: help,
                parser: :string,
                multiple: true,
                required: false
              ]}
           end)

  def command_opt_spec, do: @actions

  def speech_act_opt_spec do
    [
      created_at: [
        long: "--created-at",
        value_name: "DATE_TIME",
        help: "Time of creation of the data",
        required: false,
        default: &XSD.DateTime.now/0,
        parser: &Helper.valid_xsd_datetime/1
      ],
      created_by: [
        long: "--created-by",
        value_name: "URI",
        help: "Creator of the data",
        required: false,
        multiple: true,
        parser: :string
      ],
      data_source: [
        long: "--source",
        value_name: "URL",
        help: "Source of the data",
        required: false,
        parser: :string
      ]
    ]
  end

  def options?(%{add: value}) when value not in [nil, []], do: true
  def options?(%{update: value}) when value not in [nil, []], do: true
  def options?(%{replace: value}) when value not in [nil, []], do: true
  def options?(%{remove: value}) when value not in [nil, []], do: true
  def options?(%{}), do: false
end
