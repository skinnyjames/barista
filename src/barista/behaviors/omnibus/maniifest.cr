module Barista
  module Behaviors
    module Omnibus
      struct ManifestEntry
        getter(
          :name,
          :source_type,
          :described_version,
          :locked_version,
          :locked_source,
          :license
        )
        def initialize(
          @name : String,
          *,
          @source_type : String,
          @described_version : String,
          @locked_version : String,
          @locked_source : String,
          @license : String
        )
        end
  
        def to_json(json : JSON::Builder)
          json.object do
            json.field "name", name
            json.field "source_type", source_type
            json.field "described_version", described_version
            json.field "locked_version", locked_version
            json.field "locked_source", locked_source
            json.field "license", license
          end
        end
      end
  
      struct Manifest
        getter :project
        def initialize(@project : Barista::Behaviors::Omnibus::Project); end
  
        def to_json(json : JSON::Builder)
          json.object do
            json.field "build_version", project.build_version if project.build_version
            json.field "build_git_revision", project.build_git_revision if project.build_git_revision
            json.field "license", project.license
            json.field "manifest_format", 2
            json.field "software" do
              json.object do
                project.registry.tasks.each do |task|
                  entry = task.as(Barista::Behaviors::Omnibus::Task).to_manifest_entry
                  json.field task.name do
                    entry.to_json(json)
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
