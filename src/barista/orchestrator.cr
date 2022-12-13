module Barista
  class Orchestrator(T)
    getter :registry, :workers, :filter
    getter :task_finished, :work_done
    getter :build_list, :building, :built
    getter :colors

    getter :on_task_start, :on_task_succeed, :on_task_failed, :on_unblocked

    @build_list : Array(String)
    @on_task_start : Proc(String, Nil)?
    @on_task_succeed : Proc(String, Nil)?
    @on_task_failed : Proc(String, String, Nil)?
    @on_unblocked : Proc(Array(String), Nil)?

    def initialize(
      @registry : Barista::Registry(T), 
      *, 
      @workers : Int32 = 1, 
      @filter : Array(String)? = nil,
    )
      @building = [] of String
      @built = [] of String

      @task_finished = Channel(String | Nil).new
      @work_done = Channel(String).new

      @build_list = filter ? registry.dag.filter(filter) : registry.dag.nodes.dup
    end

    def on_task_start(&block : String -> Nil)
      @on_task_start = block
    end

    def on_task_succeed(&block : String -> Nil)
      @on_task_succeed = block
    end

    def on_task_failed(&block : String, String -> Nil)
      @on_task_failed = block
    end

    def on_unblocked(&block : Array(String) -> Nil)
      @on_unblocked = block
    end

    def execute
      # unblocker fiber
      spawn do
        loop do
          # should only have one thing at a time
          built_task = task_finished.receive

          # exit condition
          break if built_task.nil?

          # unblock exit condition
          work_done.send(built_task)

          # move task from building to built
          built << built_task
          building.delete(built_task)

          build_next
        end
      end

      # initial work fiber
      spawn do
        build_next
      end

      build_list.each do |_name|
        work_done.receive
      end

      # exit task finished loop
      task_finished.send(nil)
    end

    private def build_next
      # get all unblocked tasks that can be worked

      tasks = unblocked_queue.take_while do  |task|
        if !at_capacity?
          building << task
          true
        else
          false
        end
      end

      on_unblocked.try(&.call(tasks))

      tasks.each do |task|
        work(task)
      end
    end

    private def work(task)
      software = registry[task]

      # build this task async
      spawn do
        begin
        software.execute
        on_task_succeed.try(&.call(task))

        rescue e : Exception
          if exit_on_failure?
            on_task_failed.try(&.call(task, e.to_s))
            exit 1
          end
        ensure
          task_finished.send(task)
        end
      end
    end

    private def unblocked_queue
      build_list.select do |name|
        vertex = registry.dag.vertices[name]
        (vertex.incoming_names - built).size.zero? && !built.includes?(name) && !building.includes?(name)
      end
    end

    private def at_capacity?
      building.size >= workers
    end

    private def exit_on_failure?
      true
    end
  end
end
