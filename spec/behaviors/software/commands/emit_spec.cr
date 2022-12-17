require "../../../spec_helper"

module Barista::Behaviors::Software::Commands
  describe "Emit" do
    it "emiits errors and infos" do
      arr = [] of String

      Emit.new("foobar")
        .collect_output(arr)
        .execute        

      arr.join(", ").should match(/foobar/)
    end
  end
end