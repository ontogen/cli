defmodule Ontogen.CLI.TestFactories do
  @moduledoc """
  Test factories.
  """

  use RDF

  alias RDF.Graph

  alias Ontogen.CLI.TestNamespaces.EX
  @compile {:no_warn_undefined, Ontogen.CLI.TestNamespaces.EX}

  def id(:agent), do: ~I<http://example.com/Agent>
  def id(:agent_john), do: ~I<http://example.com/Agent/john_doe>
  def id(:agent_jane), do: ~I<http://example.com/Agent/jane_doe>
  def id(:repository), do: ~I<http://example.com/test/repo>
  def id(:repo), do: id(:repository)
  def id(:dataset), do: ~I<http://example.com/test/dataset>
  def id(:prov_graph), do: ~I<http://example.com/test/prov_graph>
  def id(resource) when is_rdf_resource(resource), do: resource
  def id(iri) when is_binary(iri), do: RDF.iri(iri)

  def datetime, do: ~U[2023-05-26 13:02:02.255559Z]

  def datetime(amount_to_add, unit \\ :second),
    do: datetime() |> DateTime.add(amount_to_add, unit)

  def statement(id) when is_integer(id) or is_atom(id) do
    {
      apply(EX, :"s#{id}", []),
      apply(EX, :"p#{id}", []),
      apply(EX, :"o#{id}", [])
    }
  end

  def statement({id1, id2})
      when (is_integer(id1) or is_atom(id1)) and (is_integer(id2) or is_atom(id2)) do
    {
      apply(EX, :"s#{id1}", []),
      apply(EX, :"p#{id2}", []),
      apply(EX, :"o#{id2}", [])
    }
  end

  def statement({id1, id2, id3} = triple)
      when (is_integer(id1) or is_atom(id1)) and
             (is_integer(id2) or is_atom(id2)) and
             (is_integer(id3) or is_atom(id3)) do
    if RDF.Triple.valid?(triple) do
      triple
    else
      {
        apply(EX, :"s#{id1}", []),
        apply(EX, :"p#{id2}", []),
        apply(EX, :"o#{id3}", [])
      }
    end
  end

  def statement(statement), do: statement

  def statements(statements) when is_list(statements) do
    Enum.flat_map(statements, fn
      statement when is_integer(statement) or is_atom(statement) or is_tuple(statement) ->
        [statement(statement)]

      statement ->
        statement |> RDF.graph() |> Graph.statements()
    end)
  end

  @graph [
           EX.S1 |> EX.p1(EX.O1),
           EX.S2 |> EX.p2(42, "Foo")
         ]
         |> RDF.graph()
  def graph, do: @graph

  def graph(statement) when is_integer(statement) or is_atom(statement) do
    statement |> statement() |> RDF.graph()
  end

  def graph(statements) when is_list(statements) do
    statements |> statements() |> RDF.graph()
  end

  def graph_file(statements, opts \\ []) do
    {file_type, opts} = Keyword.pop(opts, :type, "ttl")

    file =
      Keyword.get_lazy(opts, :file, fn ->
        "test_data_#{:erlang.unique_integer([:positive])}.#{file_type}"
      end)

    graph = graph(statements)

    RDF.write_file!(graph, file, opts)
    {graph, file}
  end
end
