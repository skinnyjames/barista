require "../../../spec_helper"

module Barista::Behaviors::Software::Commands
  describe "Emit" do
    it "emiits errors and infos" do
      cmd = Emit.new("foobar")
      arr = [] of String
      cmd.on_output do |str|
        arr << str
      end

      cmd.execute
      arr.join(", ").should match(/foobar/)
    end
  end
end