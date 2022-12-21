require "../spec_helper"

private class SequenceProject < Barista::Project; end

@[Barista::BelongsTo(SequenceProject)]
private class Gem1 < Barista::Task
  sequence ["Gems", "Other"]

  def execute
    Barista::Log.info("gem1") { "start" }
    sleep 0.3
    Barista::Log.info("gem1") { "finish" }
  end
end

@[Barista::BelongsTo(SequenceProject)]
private class Gem2 < Barista::Task
  sequence ["Gems"]

  def execute
    Barista::Log.info("gem2") { "start" }
    sleep 0.1
    Barista::Log.info("gem2") { "finish" }
  end
end

@[Barista::BelongsTo(SequenceProject)]
private class Gem3 < Barista::Task
  dependency NonGem
  sequence ["Gems"]

  def execute
    Barista::Log.info("gem3") { "start" }
    sleep 0.2
    Barista::Log.info("gem3") { "finish" }
  end
end

@[Barista::BelongsTo(SequenceProject)]
private class NonGem < Barista::Task
  sequence ["Other"]

  def execute
    Barista::Log.info("nongem") { "start" }
    Barista::Log.info("nongem") { "finish" }
  end
end

module Barista
  describe "Sequence Groups" do
    it "builds in order when providing sequences" do
      project = SequenceProject.new

      output = [] of String

      project.tasks.map(&.new)

      runner = Barista::Orchestrator.new(project.registry, workers: 4)

      with_io do |io|
        puts io
        runner.execute

        expected = [
          "gem1> start", 
          "gem1> finish", 
          "gem2> start", 
          "nongem> start", 
          "nongem> finish", 
          "gem2> finish",
          "gem3> start",
          "gem3> finish"
        ]

        regex = /#{expected.join("(.|\\n)*")}/m
        io.to_s.should match(regex)
      end
    end
  end
end