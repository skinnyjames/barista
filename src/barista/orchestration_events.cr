module Barista
  module OrchestrationEvents
    getter(
      :on_run_start, 
      :on_run_finished,
      :on_task_start, 
      :on_task_succeed, 
      :on_task_failed, 
      :on_task_finished, 
      :on_unblocked
    )

    @on_run_start : Proc(Nil) = -> { }
    @on_run_finished : Proc(Nil) = -> { }
    @on_task_start : Proc(String, Nil) = ->(task : String) { }
    @on_task_succeed : Proc(String, Nil) = ->(task : String) { }
    @on_task_failed : Proc(String, String, Nil) = ->(task : String, message : String) { }
    @on_task_finished : Proc(String, Nil) = ->(task : String) { } 
    @on_unblocked : Proc(Array(String), Nil) = ->(tasks : Array(String)) { }

    def forward_orchestration_events(other : OrchestrationEvents)
      other.on_run_start do
        on_run_start.call
      end

      other.on_run_finished do
        on_run_finished.call
      end

      other.on_task_start do |task|
        on_task_start.call(task)
      end

      other.on_task_succeed do |task|
        on_task_succeed.call(task)
      end

      other.on_task_failed do |task, ex|
        on_task_failed.call(task, ex)
      end

      other.on_task_finished do |task|
        on_task_finished.call(task)
      end

      other.on_unblocked do |tasks|
        on_unblocked.call(tasks)
      end
    end

    def on_run_start(&block : ->)
      @on_run_start = block

      self
    end

    def on_run_finished(&block : ->)
      @on_run_finished = block
      
      self
    end

    def on_task_start(&block : String -> Nil)
      @on_task_start = block
      
      self
    end

    def on_task_succeed(&block : String -> Nil)
      @on_task_succeed = block

      self
    end

    def on_task_failed(&block : String, String -> Nil)
      @on_task_failed = block

      self
    end
    
    def on_task_finished(&block : String -> Nil)
      @on_task_finished = block

      self
    end

    def on_unblocked(&block : Array(String) -> Nil)
      @on_unblocked = block

      self
    end
  end
end
