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

  def wait_for(duration : Int32 = 5, *, interval : Float64 = 0.5, &block : -> Bool)
    time = Time.local
    while (Time.local - time).seconds < duration
      begin
        result = yield
        return if result
        sleep interval
      rescue ex : Exception
        sleep interval
      end
    end
    raise Exception.new("timed out after #{duration}")
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
  ensure
    Barista::Log.backend(Log::IOBackend.new(STDOUT))
  end
end