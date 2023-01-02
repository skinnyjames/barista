class Test1
  include Barista::OrchestrationEvents

  def execute
    on_task_start.call("start")
    on_task_finished.call("test1")
  end
end

class Test2
  include Barista::OrchestrationEvents

  def initialize(@other : Barista::OrchestrationEvents)
    forward_orchestration_events(other)

    other.on_task_finished do |str|
      on_task_finished.call("#{str} foobar")
    end
  end

  def execute
    @other.execute
  end
end

module Barista
  describe "OrchestrationEvents" do
    it "forwards events" do
      test1 = Test1.new
      test2 = Test2.new(test1)

      actual = [] of String

      test2.on_task_start do |str|
        actual << str
      end

      test2.on_task_finished do |str|
        actual << str
      end

      test2.execute

      actual.should eq(["start", "test1 foobar"])
    end
  end
end
