module Barista
  class Orchestrator(T)
    getter :registry, :workers, :filter
    getter :task_finished, :work_done
    getter :build_list, :building, :built
    getter :colors

    @build_list : Array(String)
    @constructor : Proc(Barista::Task(T).class, Barista::Task(T))

    def initialize(
      @registry : Barista::Registry(Barista::Task(T).class), 
      *, 
      @workers : Int32 = 1, 
      @filter : Array(String)? = nil,
      &block : Barista::Task(T).class -> Barista::Task(T)
    )
      @constructor = block
      @building = [] of String
      @built = [] of String

      @task_finished = Channel(String | Nil).new
      @work_done = Channel(String).new

      @build_list = filter ? registry.dag.filter(filter) : registry.dag.nodes.dup
    end

    def build
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
        Log.info(T.name) { "Worker capacity: #{workers}" }

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

      Log.info(T.name) { "Unblocked tasks #{tasks}"}

      tasks.each do |task|
        work(task)
      end
    end

    private def work(task)
      software = @constructor.call(registry[task])

      # build this task async
      spawn do
        begin
        software.execute
        rescue e : Exception
          if exit_on_failure?
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
