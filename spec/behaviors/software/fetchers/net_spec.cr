require "../../../spec_helper"

module Barista::Behaviors::Software::Fetchers
  describe Net do
    it "fetches from a remote destination and unpacks it to a folder" do
      fetcher = Net.new("#{fixture_url}/test.tar.gz")
      fetcher.execute(downloads_path, "test")

      data = File.read(File.join(downloads_path, "test", "test.txt"))
      data.should eq("foobar")
    end

    it "retries on failure" do
      fetcher = Net.new("#{fixture_url}/foo.tar.gz", retry: 3)
      expect_raises(RetryExceeded, /3/) do
        fetcher.execute(downloads_path, "foo")
      end
    end
  end
end