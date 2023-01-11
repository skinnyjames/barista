require "./spec_helper"

private class InfoProject < Barista::Project
  def run
    tasks.each(&.new)

    infos = [] of Barista::OrchestrationInfo

    orchestrator = Barista::Orchestrator.new(registry, workers: 4)
    orchestrator.on_unblocked do |info|
      infos << info
    end

    orchestrator.execute

    infos
  end
end

@[Barista::BelongsTo(InfoProject)]
private class ConcurrentOne < Barista::Task
  def execute
  end
end

@[Barista::BelongsTo(InfoProject)]
private class ConcurrentTwo < Barista::Task
  def execute
    sleep 1
  end
end

@[Barista::BelongsTo(InfoProject)]
private class ConcurrentThree < Barista::Task
  dependency ConcurrentTwo

  def execute
  end
end

@[Barista::BelongsTo(InfoProject)]
private class SerialOne < Barista::Task
  sequence ["Serial"]

  def execute
    sleep 0.5
  end
end

@[Barista::BelongsTo(InfoProject)]
private class SerialTwo < Barista::Task
  sequence ["Serial", "Extra"]

  def execute
  end
end

@[Barista::BelongsTo(InfoProject)]
private class SerialThree < Barista::Task
  sequence ["Serial"]

  def execute
  end
end


module Barista
  describe "OrchestrationInfo" do
    it "tracks the state of the orchestrator" do
      infos = InfoProject.new.run
      actual = infos.map(&.to_s).join("\n\n")
      infos.size.should eq(7)

      expected = <<-EOH
      Unblocked ConcurrentOne, ConcurrentTwo, SerialOne
      Blocked  ConcurrentThree, SerialTwo, SerialThree
      Building ConcurrentOne, ConcurrentTwo, SerialOne
      Built None
      Active Sequences Serial

      Unblocked None
      Blocked  ConcurrentThree, SerialTwo, SerialThree
      Building ConcurrentTwo, SerialOne
      Built ConcurrentOne
      Active Sequences Serial

      Unblocked SerialTwo
      Blocked  ConcurrentThree, SerialThree
      Building ConcurrentTwo, SerialTwo
      Built ConcurrentOne, SerialOne
      Active Sequences Serial, Extra

      Unblocked SerialThree
      Blocked  ConcurrentThree
      Building ConcurrentTwo, SerialThree
      Built ConcurrentOne, SerialOne, SerialTwo
      Active Sequences Serial

      Unblocked None
      Blocked  ConcurrentThree
      Building ConcurrentTwo
      Built ConcurrentOne, SerialOne, SerialTwo, SerialThree
      Active Sequences None

      Unblocked ConcurrentThree
      Blocked  None
      Building ConcurrentThree
      Built ConcurrentOne, SerialOne, SerialTwo, SerialThree, ConcurrentTwo
      Active Sequences None

      Unblocked None
      Blocked  None
      Building None
      Built ConcurrentOne, SerialOne, SerialTwo, SerialThree, ConcurrentTwo, ConcurrentThree
      Active Sequences None
      EOH

      actual.should eq(expected)      
    end
  end
end