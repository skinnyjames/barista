require "../../../spec_helper"

module Barista::Behaviors::Software::Fetchers
  describe Local do
    it "fetches from a local destination and copies it to a folder" do
      fetcher = Local.new("#{fixtures_path}/sources/a-source", exclude: ["excluded", "nested/exclude/**"])
      fetcher.execute(downloads_path, "test")

      File.exists?(File.join(downloads_path, "test", "excluded")).should eq(false)
      Dir.exists?(File.join(downloads_path, "test", "nested", "exclude")).should eq(false)
      Dir.exists?(File.join(downloads_path, "test", "nested", "keep")).should eq(true)

      data = File.read(File.join(downloads_path, "test", "test.txt"))
      data.should eq("foobar")
    end
  end
end