private class LicenseProject < Barista::Project
  include Barista::Behaviors::Omnibus::Project

  @@name = "license-project"

  file("license_content", "#{__DIR__}/../../../support/fixtures/files/LICENSE")

  def initialize
    license("MIT")
    license_content(file("license_content"))
    build_version("1.1.1")
    install_dir(File.join(downloads_path, "license-project", "install"))
    barista_dir(File.join(downloads_path, "license-project", "barista"))
  end
end

@[Barista::BelongsTo(LicenseProject)]
private class Foo < Barista::Task
  include Barista::Behaviors::Omnibus::Task

  @@name = "foo"

  def initialize(@project : Barista::Behaviors::Omnibus::Project, @callbacks : Barista::Behaviors::Omnibus::CacheCallbacks)
    super(project, callbacks)
  end

  def build : Nil
    mkdir("where")
    block do
      File.write("#{source_dir}/where/LICENSE", "this is a foo license")
    end
  end

  def configure : Nil
    license("Foo 2.0")
    license_file("where/LICENSE")
    version("1")
  end
end

@[Barista::BelongsTo(LicenseProject)]
private class MutipleLicenses < Barista::Task
  include Barista::Behaviors::Omnibus::Task

  @@name = "multiple"

  def initialize(@project : Barista::Behaviors::Omnibus::Project, @callbacks : Barista::Behaviors::Omnibus::CacheCallbacks)
    super(project, callbacks)
  end

  def build : Nil
    mkdir("bar/other", parents: true)
    mkdir("something/support", parents: true)
    block do
      File.write("#{source_dir}/bar/other/LICENSE", "this is a bar license")
      File.write("#{source_dir}/something/support/NOTICE", "this is a bar notice")
    end
  end

  def configure : Nil
    license("Bar")
    license_file("bar/other/LICENSE")
    license_file("something/support/NOTICE")
    version("2")
  end
end

@[Barista::BelongsTo(LicenseProject)]
private class NoLicense < Barista::Task
  include Barista::Behaviors::Omnibus::Task

  @@name = "none"

  def initialize(@project : Barista::Behaviors::Omnibus::Project, @callbacks : Barista::Behaviors::Omnibus::CacheCallbacks)
    super(project, callbacks)
  end

  def build : Nil
    emit("no-op")
  end

  def configure : Nil
    virtual(true)
  end
end

module Barista::Behaviors::Omnibus
  describe "Licensing" do
    it "writes a licensing summary to the install dir" do
      project = LicenseProject.new
      project.cache(false)
      project.tasks.each(&.new(project, cache_callbacks))
      project.orchestrator(workers: 2).execute

      File.exists?(project.license_file_path).should eq(true)
      license_data = File.read(project.license_file_path)    
      license_data.should match(/Copyright 2022 Barista-Specs/)

      entries = Dir.children(File.join(project.install_dir, "LICENSES"))
      entries.size.should eq(3)
      ["foo-LICENSE", "multiple-LICENSE", "multiple-NOTICE"].each do |license|
        entries.should contain(license)
      end
    end

    it "restores the license artifacts from the cache" do
      project = LicenseProject.new
      project.cache(true)
      project.tasks.each(&.new(project, cache_callbacks))
      
      project.orchestrator(workers: 2).execute
      project.clean
      File.exists?(project.license_file_path).should eq(false)
      project.orchestrator(workers: 2).execute

      File.exists?(project.license_file_path).should eq(true)
      license_data = File.read(project.license_file_path)    
      license_data.should match(/Copyright 2022 Barista-Specs/)
      license_data.should match(/foo-LICENSE/)
      license_data.should match(/multiple-LICENSE/)
      license_data.should match(/multiple-NOTICE/)

      entries = Dir.children(File.join(project.install_dir, "LICENSES"))
      entries.size.should eq(3)
      ["foo-LICENSE", "multiple-LICENSE", "multiple-NOTICE"].each do |license|
        entries.should contain(license)
      end
    end
  end
end
