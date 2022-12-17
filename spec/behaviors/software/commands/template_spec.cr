require "../../../spec_helper"

module Barista::Behaviors::Software::Commands
  describe "Template" do
    it "Processes a template" do
      cmd = Template.new(
        src: File.join(fixtures_path, "templates", "test.tpl"),
        dest: File.join(downloads_path, "test"),
        mode: File::Permissions.new(0o755),
        vars: { "value" => "world" }
      )

      cmd.execute

      File.read(File.join(downloads_path, "test")).should eq("Hello world!")
    end

    it "Processes a string" do
      cmd = Template.new(
        src: "Hello {{ value }}!",
        dest: File.join(downloads_path, "test"),
        mode: File::Permissions.new(0o755),
        vars: { "value" => "world" },
        string: true
      )

      cmd.execute

      File.read(File.join(downloads_path, "test")).should eq("Hello world!")
    end
  end
end