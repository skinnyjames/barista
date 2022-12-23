require "../../../spec_helper"

private class SymlinksProject < Barista::Project
  include Barista::Behaviors::Omnibus::Project

  def initialize
    cache(true)
    barista_dir(File.join(downloads_path, "symlinks-barista"))
    install_dir(File.join(downloads_path, "symlinks-install"))
  end
end

@[Barista::BelongsTo(SymlinksProject)]
private class AbsoluteLinkTask < Barista::Task
  include Barista::Behaviors::Omnibus::Task

  @@name = "absolute"

  def initialize(@project : Barista::Behaviors::Omnibus::Project, @callbacks : Barista::Behaviors::Omnibus::CacheCallbacks)
    super(project, callbacks)
  end

  def build : Nil
    command("echo \"Absolute link content\" > #{smart_install_dir}/source_file_absolute.txt")
    link("#{smart_install_dir}/source_file_absolute.txt", "#{smart_install_dir}/absolute_link")
  end

  def configure : Nil
    cache(true)
    virtual(true)
    preserve_symlinks(false)
  end
end

@[Barista::BelongsTo(SymlinksProject)]
private class RelativeLinkTask < Barista::Task
  include Barista::Behaviors::Omnibus::Task

  @@name = "relative"

  def initialize(@project : Barista::Behaviors::Omnibus::Project, @callbacks : Barista::Behaviors::Omnibus::CacheCallbacks)
    super(project, callbacks)
  end

  def build : Nil
    mkdir("#{smart_install_dir}/nested", parents: true)
    command("echo \"Relative link content\" > #{smart_install_dir}/nested/source_file_relative.txt")
    link("nested/source_file_relative.txt", "relative_link", chdir: smart_install_dir)
  end

  def configure : Nil
    cache(true)
    virtual(true)
    preserve_symlinks(false)
  end
end

@[Barista::BelongsTo(SymlinksProject)]
private class AbsoluteWithPreserveTask < Barista::Task
  include Barista::Behaviors::Omnibus::Task

  @name = "absolute-with-preserve"

  def initialize(@project : Barista::Behaviors::Omnibus::Project, @callbacks : Barista::Behaviors::Omnibus::CacheCallbacks)
    super(project, callbacks)
  end

  def build : Nil
    command("echo \"Absolute link content\" > #{smart_install_dir}/preserve.txt")
    link("#{install_dir}/preserve.txt", "#{smart_install_dir}/absolute_preserve")
  end

  def configure : Nil
    cache(true)
    virtual(true)
    preserve_symlinks(true)
  end
end

def with_symlink_project
  project = SymlinksProject.new
  project.tasks.each do |klass|
    task = klass.new(project, cache_callbacks).as(Barista::Behaviors::Omnibus::Task)

    task.on_output { |str| puts task.name + " " + str }
    task.on_error { |str| puts task.name + " error " + str}
  end

  # run once so we repopulate from the cache
  project.registry.tasks.each(&.execute)
  project.clean!
  project.registry.tasks.each(&.execute)
  yield(project)
ensure
  project.try(&.registry.reset)
end

module Barista::Behaviors::Omnibus
  describe "Caching Symlinks" do
    it "reconstructs absolute symlinks" do
      with_symlink_project do |project|
        absolute_link = File.join(downloads_path, "symlinks-install", "absolute_link")
        File.exists?(absolute_link).should eq(true)
        File.readlink(absolute_link).should eq(File.join(downloads_path, "symlinks-install", "source_file_absolute.txt"))
      end
    end

    it "reconstructs relative symlinks" do
      with_symlink_project do |project|
        relative_link = File.join(downloads_path, "symlinks-install", "relative_link")
        File.exists?(relative_link).should eq(true)
        File.readlink(relative_link).should eq("nested/source_file_relative.txt")
      end
    end

    it "doesn't reconstruct when preserve_symlinks is true" do
      with_symlink_project do |project|
        link = File.join(downloads_path, "symlinks-install", "absolute_preserve")
        File.exists?(link).should eq(true)
        File.readlink(link).should eq(File.join(downloads_path, "symlinks-install", "preserve.txt"))
      end
    end
  end
end
