require "../../../spec_helper"

module Barista::Behaviors::Software::Commands
  describe "Command" do
    it "runs arbitrary shell commands" do
      output = [] of String    
      Command.new("cat command.txt", chdir: "#{fixtures_path}/commands")
        .collect_output(output)
        .execute

      output.join(" ").should match(/hello world/)
    end
  end
end