private class LicenseProject < Barista::Project
  include Barista::Behaviors::Omnibus::Project

  @@name = "license-project"

  def initialize
    build_version("1.2.3")
    license("Custom")
    license_content("Custom license")
    install_dir("#{downloads_path}/lcollect/install")
    barista_dir("#{downloads_path}/lcollect/barista")
  end
end

@[Barista::BelongsTo(LicenseProject)]
private class NoLicenseTask < Barista::Task
  include Barista::Behaviors::Omnibus::Task

  @@name = "no-license"

  def build : Nil; end
  def configure : Nil; 
    version("1.2.3")
  end
end

@[Barista::BelongsTo(LicenseProject)]
private class ALicenseTask < Barista::Task
  include Barista::Behaviors::Omnibus::Task

  @@name = "a-license"

  def build : Nil
    block do
      File.write("#{source_dir}/something", "hello world")
    end
  end

  def configure : Nil
    license("A-License")
    license_file("something")
    version("1.2.3")
  end
end

@[Barista::BelongsTo(LicenseProject)]
private class BrokenLicenseTask < Barista::Task
  include Barista::Behaviors::Omnibus::Task

  @@name = "broken-license"

  def build : Nil; end

  def configure : Nil
    license("Broken")
    license_file("nonexistant")
    version("1.2.3")
  end
end

module Barista::Behaviors::Omnibus
  describe "LicenseCollector" do
    before_each do
      LicenseProject.reset_registry
    end

    it "compiles a project summary" do
      project = LicenseProject.new
      collector = LicenseCollector.new(project)

      expected = <<-EOH
      license-project 1.2.3 license: "Custom"

      Custom license
      
      EOH

      collector.write_summary

      File.exists?(project.license_file_path).should eq(true)
      File.read(project.license_file_path).should eq(expected)
    end

    it "compiles a project license with task summary" do
      project = LicenseProject.new
      collector = LicenseCollector.new(project)
      
      a_license_task = ALicenseTask.new(project)
      a_license_task.execute

      collector << a_license_task

      expected = <<-EOH
      This product bundles a-license 1.2.3,
      which is available under a "A-License" License.
      For details, see:
      #{project.install_dir}/LICENSES/a-license-something
      
      EOH

      collector.tasks_summary.should eq(expected)
    end

    it "throws if a task's license cannot be found" do
      project = LicenseProject.new
      collector = LicenseCollector.new(project)

      broken = BrokenLicenseTask.new(project)

      expect_raises(LicenseMissingError, /nonexistant does not exist for broken-license/) do
        collector << broken
      end
    end

    it "uses a standin for no license" do
      project = LicenseProject.new
      collector = LicenseCollector.new(project)
      no_license_task = NoLicenseTask.new(project)
      collector << no_license_task

      expected = <<-EOH
      This product bundles no-license 1.2.3,
      which is available under a "Unspecified" License.
      
      EOH

      collector.tasks_summary.should eq(expected)
    end
  end
end
