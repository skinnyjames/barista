require "../../../spec_helper"

private class ShasumProject < Barista::Project
  include Barista::Behaviors::Omnibus::Project
  
  def initialize
    barista_dir(File.join(downloads_path, "shasum-barista"))
    install_dir(File.join(downloads_path, "shasum-install"))
  end
end

@[Barista::BelongsTo(ShasumProject)]
private class TaskOne < Barista::Task
  include Barista::Behaviors::Omnibus::Task

  def build : Nil
    block do
      puts "hello world"
    end
  end

  def configure : Nil
    virtual(true)
  end
end

@[Barista::BelongsTo(ShasumProject)]
private class TaskOneDup < Barista::Task
  include Barista::Behaviors::Omnibus::Task

  def build : Nil
    block do
      puts "hello world"
    end
  end

  def configure : Nil
    virtual(true)
  end
end

@[Barista::BelongsTo(ShasumProject)]
private class TaskTwo < Barista::Task
  include Barista::Behaviors::Omnibus::Task

  def build : Nil
    block do
      puts "hello world"
    end

    block do
      puts "hello again"
    end
  end

  def configure : Nil
    virtual(true)
  end
end

@[Barista::BelongsTo(ShasumProject)]
private class TaskTwoDup < Barista::Task
  include Barista::Behaviors::Omnibus::Task

  def build : Nil
    block do
      puts "hello world"
    end

    block do
      puts "hello again"
    end
  end

  def configure : Nil
    virtual(true)
  end
end

@[Barista::BelongsTo(ShasumProject)]
private class TaskThree < Barista::Task
  include Barista::Behaviors::Omnibus::Task

  def build : Nil
    block do
      puts "hello world"
    end

    block do
      puts "hello again again"
    end
  end

  def configure : Nil
    virtual(true)
  end
end

module Barista::Behaviors::Omnibus
  describe "blockstrings" do
    it "keeps the same digest if the blockstrings are the same" do
      project = ShasumProject.new
      task1 = TaskOne.new(project)
      task1dup = TaskOneDup.new(project)
      
      task1.shasum.should eq(task1dup.shasum)
    end

    it "changes the digest if a new block is introduced" do
      project = ShasumProject.new
      task1 = TaskOne.new(project)
      task2 = TaskTwo.new(project)

      task1.shasum.should_not eq(task2.shasum)
    end

    it "keeps the same digest if multiple blocks are the same" do
      project = ShasumProject.new
      task2 = TaskTwo.new(project)
      task2dup = TaskTwoDup.new(project)
      
      task2.shasum.should eq(task2dup.shasum)
    end

    it "changes the digest if the same block is different" do
      project = ShasumProject.new
      task2 = TaskTwo.new(project)
      task3 = TaskThree.new(project)

      task2.shasum.should_not eq(task3.shasum)
    end
  end
end
