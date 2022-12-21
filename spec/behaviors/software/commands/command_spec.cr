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

    it "raises if the handler throws" do
      arr = [] of String

      e = Command.new("ls")
        .on_output { |f| raise "bad" }
      
      expect_raises(CommandError, "bad") do
        e.execute
      end
    end
  end
end