require "../../../spec_helper"

module Barista::Behaviors::Software::Commands
  describe "Link" do
    it "creates a softlink from <source> to <dest>" do
      File.write(File.join(downloads_path, "test.txt"), "link")

      Link.new(
        File.join(downloads_path, "test.txt"),
        File.join(downloads_path, "linked")
      ).execute

      File.symlink?(File.join(downloads_path, "linked")).should eq(true)
      File.readlink(File.join(downloads_path, "linked")).should eq(File.join(downloads_path, "test.txt"))
    end
  end
end