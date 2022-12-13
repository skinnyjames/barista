require "../../../spec_helper"

module Barista::Behaviors::Software::Commands
  describe "Block" do
    it "Executes an arbitrary block" do
      foo = ""

      cmd = Block.new("edit foo") do
        foo = "hello world"
      end

      foo.should eq("")

      cmd.execute

      foo.should eq("hello world")
    end
  end
end