require "../../spec_helper"

private class CacheProject < Barista::Project
  include Barista::Behaviors::Omnibus::Project

  def initialize
    cache(true)
    barista_dir(File.join(downloads_path, "barista-caching"))
    install_dir(File.join(downloads_path, "caching"))
  end
end

@[Barista::BelongsTo(CacheProject)]
private class CacheTask1 < Barista::Task
  include Barista::Behaviors::Omnibus::Task

  def initialize(@project : Barista::Behaviors::Omnibus::Project, @callbacks : Barista::Behaviors::Omnibus::CacheCallbacks)
    super(project, callbacks)
  end

  def build : Nil
  end

  def configure : Nil
    cache(true)
  end
end

@[Barista::BelongsTo(CacheProject)]
private class CacheTask2 < Barista::Task
  include Barista::Behaviors::Omnibus::Task

  dependency CacheTask1

  def initialize(@project : Barista::Behaviors::Omnibus::Project, @callbacks : Barista::Behaviors::Omnibus::CacheCallbacks)
    super(project, callbacks)
  end

  def build : Nil
    copy("test.txt", File.join(smart_install_dir, "test.txt"))
    command("echo \"baz\" >> test.txt", chdir: smart_install_dir)
  end

  def configure : Nil
    cache(true)
    source("#{fixture_url}/test.tar.gz")
  end
end

module Barista::Behaviors::Omnibus
  describe "Caching" do
    it "updates the cache with the build results" do
      project = CacheProject.new
      project.tasks.each(&.new(project, cache_callbacks))

      task = project.registry["CacheTask2"].as(Barista::Behaviors::Omnibus::Task)

      task.on_output do |s|
        Barista::Log.info(task.name) { s }
      end

      task.on_error do |s|
        Barista::Log.error(task.name) { s }
      end

      # will run CacheTask1 first
      # then cache the result of CacheTask2
      task.execute
      cached_file = File.join(cache_path, "#{task.tag}.tar.gz")

      File.exists?(cached_file).should eq(true)

      File.read(File.join(project.install_dir, "test.txt")).chomp.should eq("foobarbaz")

      # # clean project directories
      project.clean

      # running execute again will restore from the cache
      with_io do |io|
        task.execute
        
        wait_for(interval: 0.2) do
          puts(io)
          !!(io.to_s =~ /cache restore succeeded/m)
        end
        
        io.to_s.should match(/cache restore succeeded/m)
      end


      File.read(File.join(task.stage_install_dir, "test.txt")).chomp.should eq("foobarbaz")
      File.read(File.join(task.install_dir, "test.txt")).chomp.should eq("foobarbaz")
    end
  end
end
