require "../../../spec_helper"

module Barista::Behaviors::Software::Commands
  describe "Command" do
    it "runs arbitrary shell commands" do
      cmd = Command.new("cat command.txt", chdir: "#{fixtures_path}/commands")
      output = [] of String
      cmd.on_output do |str|
        output << str
      end

      cmd.execute

      output.join(" ").should match(/hello world/)
    end
  end
end