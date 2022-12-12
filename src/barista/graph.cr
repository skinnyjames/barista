module Barista
  class GraphCyclicalError < Exception; end

  # A simple Directed Acyclic Graph
  class Graph
    getter :nodes, :vertices

    def initialize(@nodes = [] of String, @vertices = {} of String => Vertex); end

    # Adds a task name to the Graph
    def add(node : String)
      if vertex = vertices[node]?
        return vertex
      end

      vertex = Vertex.new(name: node)
      vertices[node] = vertex
      nodes << node

      vertex
    end

    def add(node : Symbol)
      add(node.to_s)
    end

    # Connects 2 tasks in the Graph
    # with an edge
    def add_edge(from : String, to : String) : Nil
      return if from == to

      from_vertex = add(from)
      to_vertex = add(to)

      return if to_vertex.incoming[from]?

      Graph::Visitor.visit(from_vertex, ensure_non_cylical(to))

      from_vertex.has_outgoing = true

      to_vertex.incoming[from] = from_vertex
      to_vertex.incoming_names << from

      # update the dictionary with latest
      vertices[from] = from_vertex
      vertices[to] = to_vertex
    end

    def add_edge(from : Symbol, to : Symbol)
      add_edge(from.to_s, to.to_s)
    end

    # Fetch a flat list of dependencies
    # given an array of task names
    def filter(names, result = names.dup)
      return result.uniq if names.empty?
      name = names.shift

      vertex = vertices[name]
      result = (result + vertex.incoming_names)

      result.concat filter((vertex.incoming_names - names), result)
      filter(names, result)
    end

    private def ensure_non_cylical(to : String) : Graph::Visitor::Callback
      -> (vertex : Vertex, path : Array(String)) do
        if vertex.name == to
          raise GraphCyclicalError.new("Cyclical reference detected: #{to} <- #{path.join(" <- ")}")
        end
      end
    end
  end

  # Representation of a Vertex in the Graph
  struct Graph::Vertex
    property :name, :incoming, :incoming_names, :has_outgoing

    def initialize(
      *,
      @name : String,
      @incoming = {} of String => Graph::Vertex,
      @incoming_names = [] of String,
      @has_outgoing = false,
    )
    end

    def has_outgoing?
      @has_outgoing
    end
  end

  # Visitor singleton
  struct Graph::Visitor
    alias Callback = Proc(Vertex, Array(String), Nil)

    def self.visit(
      vertex : Graph::Vertex,
      callback : Callback,
      visited = {} of String => Bool,
      path = [] of String
    )

      node = vertex.name
      incoming = vertex.incoming
      incoming_names = vertex.incoming_names

      return if visited[node]?

      path << node
      visited[node] = true

      incoming_names.each do |name|
        visit(incoming[name], callback, visited, path)
      end

      callback.call(vertex, path)
      path.pop
    end
  end
end
