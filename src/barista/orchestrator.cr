module Barista
  class Orchestrator(T)
    include OrchestrationEvents
    
    getter :registry, :workers, :filter
    getter :task_finished, :work_done
    getter :build_list, :building, :built, :active_sequences
    getter :colors

    @build_list : Array(String)

    def initialize(
      @registry : Barista::Registry(T), 
      *, 
      @workers : Int32 = 1, 
      @filter : Array(String)? = nil,
    )
      @building = [] of String
      @built = [] of String

      @active_sequences = Sequences.new

      @task_finished = Channel(String | Nil).new
      @work_done = Channel(String | Exception).new

      @build_list = filter ? registry.dag.filter(filter) : registry.dag.nodes.dup
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

          obj = registry[built_task]

          # move task from building to built
          # and remove the task from the active sequences
          built << built_task
          building.delete(built_task)
          active_sequences.remove(obj)

          build_next
        end
      end

      # initial work fiber
      spawn do
        on_run_start.call
        build_next
      end

      build_list.each do |_name|
        message = work_done.receive
        if message.is_a?(Exception)
          on_run_finished.call
          raise "Build raised exception: #{message}"
        end
      end

      # exit task finished loop
      task_finished.send(nil)
      on_run_finished.call
    end

    private def build_next
      tasks = unblocked_queue.reduce([] of String) do |accepted, name|
        break(accepted) if at_capacity?

        task = registry[name]

        # skip if there is an active sequence
        next(accepted) if !active_sequences.empty? && active_sequences.includes_task?(task)

        active_sequences << task
        accepted << name
        building << name

        accepted
      end

      orchestration_info = OrchestrationInfo.new(
        unblocked: tasks.dup,
        blocked: build_list.dup - (building.dup + built.dup),
        building: building.dup,
        built: built.dup,
        active_sequences: active_sequences.sequences.dup
      )

      on_unblocked.call(orchestration_info)

      tasks.each do |task|
        work(task)
      end
    end

    private def work(task)
      software = registry[task]
      on_task_start.call(task)

      # build this task async
      spawn do
        begin
          software.execute
          on_task_succeed.call(task)
        rescue ex
          if exit_on_failure?
            on_task_failed.call(task, ex.to_s)
            task_finished.send(nil)
            work_done.send(ex)
          end
        ensure
          on_task_finished.call(task)
          task_finished.send(task)
        end
      end
    end

    private def unblocked_queue
      unblocked = build_list.select do |name|
        task = registry[name]
        vertex = registry.dag.vertices[name]

        (vertex.incoming_names - built).size.zero? && 
          !built.includes?(name) && 
            !building.includes?(name)
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
