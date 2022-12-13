require "../../../spec_helper"

module Barista::Behaviors::Software::Commands
  describe "Mkdir" do
    it "Makes a directory (recursive)" do
      dir = File.join(downloads_path, "one", "two", "three")
      Dir.exists?(dir).should eq(false)

      Mkdir.new(dir).execute

      Dir.exists?(dir).should eq(true)
    end
  end
end