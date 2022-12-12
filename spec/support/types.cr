class Coffeeshop < Barista::Project; end

module Barista::Registerable; end
struct MockTask
  include Barista::Registerable
  getter :name, :value, :dependencies
  def initialize(@name : String, @value : String, @dependencies : Array(Barista::Registerable) = [] of Barista::Registerable); end
end

module WithHelpers
  def with_graph(*, nodes = [] of Symbol, edges = [] of Tuple(Symbol, Symbol), &block : ->)
    graph = Barista::Graph.new
    nodes.each do |node|
      graph.add(node)
    end

    edges.each do |tuple|
      graph.add_edge(tuple[0], tuple[1])
    end

   yield graph
  end

  def io
    io = IO::Memory.new
    multi = IO::MultiWriter.new(io, STDOUT)
    { io, multi }
  end

  def with_io
    io, multi = io
    Barista::Log.backend(Log::IOBackend.new(multi))
    yield(io)
  end
end