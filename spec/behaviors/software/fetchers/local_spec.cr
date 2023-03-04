require "../../../spec_helper"

module Barista::Behaviors::Software::Fetchers
  describe Local do
    it "fetches from a local destination and copies it to a folder" do
      fetcher = Local.new("#{fixtures_path}/sources/a-source")
      fetcher.execute(downloads_path, "test")

      data = File.read(File.join(downloads_path, "test", "test.txt"))
      data.should eq("foobar")
    end
  end
end