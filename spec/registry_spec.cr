require "./spec_helper"

module Barista
  describe "Registry" do
    it "collects tasks" do
      one = MockTask.new(name: "one", value: "foo")
      two = MockTask.new(name: "two", value: "bar")
      three = MockTask.new(name: "three", value: "baz")

      registry = Barista::Registry(Registerable).new
      [one, two, three].each { |registerable| registry << registerable }

      registry.tasks.size.should eq(3)
      registry.dag.should be_a(Barista::Graph)
    end

    it "fetches a single task by name" do
      one = MockTask.new(name: "one", value: "foo")
      two = MockTask.new(name: "two", value: "bar", dependencies: [one] of Registerable)

      registry = Barista::Registry(Registerable).new
      [one, two].each { |registerable| registry << registerable }
    
      actual = registry["two"]
      actual.dependencies.should eq([one])
    end

    it "fetches upstreams dependencies" do
      one = MockTask.new(name: "one", value: "foo")
      two = MockTask.new(name: "two", value: "bar", dependencies: [one] of Registerable)
      three = MockTask.new(name: "three", value: "baz", dependencies: [one] of Registerable)
      four = MockTask.new(name: "four", value: "buzz", dependencies: [two] of Registerable)

      registry = Barista::Registry(Registerable).new
      [one, two, three, four].each { |registerable| registry << registerable }
    
      registry.upstreams(four).should eq([one, two])
    end
  end
end
