require "../../spec_helper"

private class ManifestProject < Barista::Project
  include Barista::Behaviors::Omnibus::Project

  def initialize
    build_version("1.2.3")
  end
end

@[Barista::BelongsTo(ManifestProject)]
private class ManifestTask1 < Barista::Task
  include Barista::Behaviors::Omnibus::Task

  @@name = "manifest-task1"

  def initialize(@project : Barista::Behaviors::Omnibus::Project)
    super(project)
  end

  def build : Nil
  end

  def configure : Nil
    version("1.2.3")
    source("#{fixture_url}/files/test.tar.gz")
    license("MIT")
  end
end

@[Barista::BelongsTo(ManifestProject)]
private class ManifestTask2 < Barista::Task
  include Barista::Behaviors::Omnibus::Task

  @@name = "manifest-task2"

  def initialize(@project : Barista::Behaviors::Omnibus::Project)
    super(project)
  end

  def build : Nil
  end

  def configure : Nil
    version("1.2.3")
    source("#{fixture_url}/files/test.tar.gz")
    license("MIT")
  end
end

module Barista::Behaviors::Omnibus
  describe "Manifest" do
    it "creates a manifest entry per task" do
      project = ManifestProject.new
      task = ManifestTask1.new(project)
      entry = task.to_manifest_entry
      entry.name.should eq("manifest-task1")
      entry.locked_version.should eq("1.2.3")
      entry.described_version.should eq("1.2.3")
      entry.license.should eq("MIT")
      entry.locked_source.should eq("#{fixture_url}/files/test.tar.gz")
    end

    it "returns a json manifest" do
      project = ManifestProject.new
      task = ManifestTask1.new(project)
      task2 = ManifestTask2.new(project)
      
      json = project.manifest.to_pretty_json
      json.should be_a(String)
    end
  end
end