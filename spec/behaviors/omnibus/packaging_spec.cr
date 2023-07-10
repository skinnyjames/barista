require "../../spec_helper"

private class PackageProject < Barista::Project
  include Barista::Behaviors::Omnibus::Project

  def initialize
    barista_dir(File.join(downloads_path, "package", "barista"))
    install_dir(File.join(downloads_path, "package", "install"))
    package_dir(File.join(downloads_path, "package", "pkg"))
    maintainer("Sean Gregory")
    homepage("https://gitlab.com/skinnyjames/barista")
    build_version("1.2.3")
    license("Foobar")
    package_name("a@certain&package+123.$thing")
    description("First line\n\nThird line")
    package_scripts_path(File.join(fixtures_path, "package_scripts", "rpm"))
    validate_package_fields
  end
end

@[Barista::BelongsTo(PackageProject)]
private class PackageTask1 < Barista::Task
  include Barista::Behaviors::Omnibus::Task

  def initialize(@project : Barista::Behaviors::Omnibus::Project)
    super(project)
  end

  def build : Nil
    command("echo \"addy\" > test.txt")
    copy("test.txt", install_dir)
  end

  def configure : Nil
    version("1.2.3")
    source("#{fixture_url}/test.tar.gz")
  end
end

module Barista::Behaviors::Omnibus
  describe "Packaging" do
    if Barista::Behaviors::Omnibus::Packager.supported?
      it "packages for the platform" do
        project = PackageProject.new
        task1 = PackageTask1.new(project)

        packager = Barista::Behaviors::Omnibus::Packager.discover(project)

        case project.platform.family
        when "debian", "ubuntu"
          packager.should be_a(Barista::Behaviors::Omnibus::Packagers::Deb)
        when "centos", "redhat", "fedora"
          packager.should be_a(Barista::Behaviors::Omnibus::Packagers::Rpm)
        end
      end

      it "creates the package" do
        project = PackageProject.new
        task1 = PackageTask1.new(project)
        task1.execute
        output = [] of String

        packager = Barista::Behaviors::Omnibus::Packager.discover(project)

        if packager.is_a?(Barista::Behaviors::Omnibus::Packagers::Pkg)
          packager.identifier("com.barista.addy")
        end

        packager.on_output do |str|
          Barista::Log.info("Packaging <#{packager.class}>") { str }
          output << str
        end

        packager.on_error do |str|
          Barista::Log.error("Packaging <#{packager.class}>") { str }
          raise "#{str}"
        end

        packager.run

        File.exists?(File.join(project.package_dir, packager.package_name)).should eq(true)

        packager.query
        packager.list_files

        output.any? { |f| /test\.txt/.matches?(f) }.should eq(true)
      end
    else
      pending "runs tests against #{Barista::Behaviors::Omnibus::Packager.platform.family}"
    end
  end
end