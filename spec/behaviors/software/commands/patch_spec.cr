require "../../../spec_helper"

module Barista::Behaviors::Software::Commands
  describe "Patch" do
    it "Patches a file" do
      patch_dir =  File.join(downloads_path, "patches")
      Sync.new(File.join(fixtures_path, "patches"), patch_dir).execute


      Patch.new(File.join(patch_dir, "patch_file_to_patch.patch"), plevel: 0, chdir: patch_dir).execute
      expected = File.read(File.join(patch_dir, "modified_file.yml"))
      actual = File.read(File.join(patch_dir, "file_to_patch.yml"))

      actual.should eq(expected)
    end
  end
end