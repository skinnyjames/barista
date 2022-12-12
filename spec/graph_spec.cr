require "./spec_helper"

module Barista
  describe Graph do
    describe "#add" do
      it "can add a node" do
        with_graph(nodes: ["foo", "bar"]) do |graph|
          graph.nodes.should eq(["foo", "bar"])
        end
      end

      it "returns a vertex with no edges" do
        with_graph do |graph|
          v1 = graph.add("foo")
          v1.should be_a(Graph::Vertex)
          v1.incoming_names.should eq([] of Symbol)
        end
      end
    end

    describe "#add_edge" do
      it "connects two nodes" do
        with_graph(nodes: ["foo", "bar"]) do |graph|
          graph.add_edge("foo", "bar")
          foo = graph.vertices["foo"]
          foo.incoming_names.should eq([] of Symbol)
          foo.has_outgoing?.should eq(true)

          bar = graph.vertices["bar"]
          bar.incoming_names.should eq(["foo"])
          bar.has_outgoing?.should eq(false)
        end
      end

      it "can connect a node hierarchy" do
        with_graph(
          nodes: ["foo", "bar", "buzz"],
          edges: [{ "foo", "bar",}, { "foo", "buzz" }, { "bar", "buzz" }]
        ) do |graph|
          buzz = graph.vertices["buzz"]
          buzz.incoming_names.should eq(["foo", "bar"])
          buzz.has_outgoing?.should eq(false)

          bar = graph.vertices["bar"]
          bar.incoming_names.should eq(["foo"])
          bar.has_outgoing?.should eq(true)

          foo = graph.vertices["foo"]
          foo.incoming_names.should eq([] of Symbol)
          foo.has_outgoing?.should eq(true)
        end
      end

      it "raises an exception on cyclical reference" do
        with_graph(nodes: ["foo", "bar", "baz", "buzz"], edges: [{ "foo", "bar" }, { "bar", "baz" }, { "buzz", "foo" }]) do |graph|
          expect_raises(GraphCyclicalError, "Cyclical reference detected: buzz <- baz <- bar <- foo <- buzz") do
            graph.add_edge("baz", "buzz")
          end
        end
      end
    end

    describe "#filter" do
      it "returns a list of tasks that match the filtered tree" do
        with_graph(nodes: ["a", "b", "c", "d", "e"], edges: [{ "a", "e" }, { "c", "e" }]) do |graph|
          graph.filter(["e", "b"]).should eq(["e", "b", "a", "c"])
        end
      end

      it "filters with a nested hierarchy" do
        with_graph(nodes: ["a", "b", "c", "d", "e", "f", "g", "h"], edges: [{ "a", "c" }, { "c", "d" }, { "c", "f" }, { "c", "h" }, { "h", "e" }]) do |graph|
          graph.filter(["e"]).should eq(["e", "h", "c", "a"])
        end
      end
    end
  end
end
