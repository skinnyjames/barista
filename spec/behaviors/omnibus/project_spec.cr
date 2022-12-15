require "../../spec_helper"

private class IncompleteProject < Barista::Project
  include Barista::Behaviors::Omnibus::Project
end

alias MissingAttr = Barista::Behaviors::Omnibus::MissingRequiredAttribute

module Barista::Behaviors::Omnibus
  describe "Project" do
    it "throws on missing required fields" do
      project = IncompleteProject.new
      
      expect_raises(MissingAttr) { project.homepage }
      expect_raises(MissingAttr) { project.maintainer }
      expect_raises(MissingAttr) { project.build_version }
      expect_raises(MissingAttr) { project.install_dir }
      expect_raises(MissingAttr) { project.barista_dir }

      # these raise on virtue of using barista_dir
      expect_raises(MissingAttr) { project.cache_dir }
      expect_raises(MissingAttr) { project.stage_dir }
      expect_raises(MissingAttr) { project.source_dir }
    end

    it "tracks the shasum based on #name and #install_dir" do
      project = IncompleteProject.new
      project2 = IncompleteProject.new

      project.install_dir("Bar")
      project2.install_dir("Baz")

      project.shasum.should_not eq(project2.shasum)

      project2.install_dir("Bar")

      project.shasum.should eq(project2.shasum)
    end

    it "cleans the install and barista paths" do
      project = IncompleteProject.new
      project.install_dir(File.join(downloads_path, "incomplete", "install"))
      project.barista_dir(File.join(downloads_path, "incomplete", "barista"))

      path = File.join("foo", "bar", "baz")

      mkdir(File.join(project.install_dir, path))
      mkdir(File.join(project.barista_dir, path))


      [project.install_dir, project.barista_dir].each do |dir|
        Dir.exists?(File.join(dir, path)).should eq(true)
      end

      project.clean

      [project.install_dir, project.barista_dir].each do |dir|
        Dir.exists?(File.join(dir, path)).should eq(false)
      end
    end
  end
end
