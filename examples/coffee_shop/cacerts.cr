@[Barista::BelongsTo(Coffeeshop)]
class CaCerts < Barista::Task
  include Barista::Behaviors::Omnibus::Task

  @@name = "cacerts"

  getter :source_url

  def initialize(@project : Barista::Behaviors::Omnibus::Project)
    super(project)

    @source_url = "https://curl.haxx.se/ca/cacert-#{version.gsub(".", "-")}.pem"
  end

  def build : Nil
    dest = File.join(install_dir, "embedded", "ssl", "certs")
    block do
      mkdir(dest, parents: true).execute
      Crest.get(source_url) do |res|
        File.write("#{dest}/cacert.pem", res.body_io)
      end
    end

    link("certs/cacert.pem", "cacert.pem", chdir: File.join(install_dir, "embedded", "ssl"))

    block do
      File.chmod(File.join(dest, "cacert.pem"), 644)
    end
  end

  def configure : Nil
    version("2022.07.19")
  end
end
