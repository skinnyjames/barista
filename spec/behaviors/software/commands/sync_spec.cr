require "../../../spec_helper"

module Barista::Behaviors::Software::Commands
  describe "Sync" do
    it "Syncs from <src> to <dest>" do
      output = [] of String
      cmd = Sync.new(File.join(fixtures_path, "commands"), File.join(downloads_path, "commands"))
              .collect_output(output)
              .collect_error(output)
              .execute

      output.join(" ").should match(/Syncing/)
      File.read(File.join(downloads_path, "commands", "command.txt")).should match(/hello world/)
    end

    it "Excludes files from the Sync" do
      cmd = Sync.new(File.join(fixtures_path, "commands"), File.join(downloads_path, "commands"), exclude: ["#{fixtures_path}/commands/command.txt"])
      cmd.execute

      File.exists?(File.join(downloads_path, "commands", "command.txt")).should eq(false)
    end
  end
end