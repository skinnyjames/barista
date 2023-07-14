require "../../spec_helper"
require "../../../src/barista_spec"
require "./project/*"

module Internal
  describe "Provider" do
    it "mocks the required files" do
      with_webmock do
        provider = BaristaSpec::Omnibus::Provider.new("#{downloads_path}/internal/serve", "#{__DIR__}/project/provides.yml")    

        project = Provides.new

        begin
          project.build(provider)
        rescue ex
          ex.should eq(nil)
        ensure
          provider.restore_env
        end
      end
    end
  end
end
