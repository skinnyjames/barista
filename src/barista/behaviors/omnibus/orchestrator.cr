module Barista
  module Behaviors
    module Omnibus
      class Orchestrator
        include OrchestrationEvents
        
        @orchestrator : Barista::Orchestrator(Barista::Task)

        getter :orchestrator, :project

        def initialize(@project : Barista::Behaviors::Omnibus::Project, **opts)
          @orchestrator = Barista::Orchestrator(Barista::Task).new(project.registry, **opts)

          setup_hooks(orchestrator)
        end

        def execute
          orchestrator.execute
        end

        private def setup_hooks(orchestrator)
          forward_orchestration_events(orchestrator)

          orchestrator.on_run_finished do
            project.license_collector.write_summary

            on_run_finished.call
          end
        end
      end
    end
  end
end
