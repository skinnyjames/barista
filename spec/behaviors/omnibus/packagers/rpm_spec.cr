require "../../../spec_helper"

private class RpmProject < Barista::Project
  include Barista::Behaviors::Omnibus::Project

  def initialize
    install_dir(File.join(downloads_path, "rpm-project"))
    barista_dir(File.join(downloads_path, "barista"))
    package_dir(File.join(downloads_path, "package"))
    maintainer("Sean Gregory")
    homepage("https://gitlab.com/skinnyjames/barista")
    build_version("1@version2_rule#them.all")
    license("Foobar")
    package_name("a@certain&package+123.$thing")
    description("First line\n\nThird line")
    package_scripts_path(File.join(fixtures_path, "package_scripts", "rpm"))
    validate_package_fields
  end
end

module Barista::Behaviors::Omnibus::Packagers
  describe "Rpm" do
    it "sets compression" do
      project = RpmProject.new
      packager = Rpm.new(project)

      [{nil, nil, "w9.gzdio"}, {:bzip2, 3, "w3.bzdio"}, {:xz, 8, "w8.xzdio"}].each do |t|
        packager.compression_level(t[1])
        packager.compression_type(t[0])

        packager.compression.should eq(t[2])
      end
    end

    it "defaults fields" do
      project = RpmProject.new
      packager = Rpm.new(project)

      packager.license.should eq("Foobar")
      packager.category.should eq("default")
      packager.priority.should eq("extra")
      packager.signing_passphrase.should eq(nil)
    end

    it "creates rpm safe strings" do
      project = RpmProject.new
      packager = Rpm.new(project)

      packager.rpm_safe("string with spaces").should eq("\"string with spaces\"")
      packager.rpm_safe("[*?%").should eq("[\\[][*][?][%]")
    end

    it "sanitizes the package name" do
      project = RpmProject.new
      packager = Rpm.new(project)

      packager.safe_package_name.should eq("a-certain-package+123.-thing")
    end

    it "sanitizes the package version" do
      project = RpmProject.new
      packager = Rpm.new(project)

      packager.safe_version.should eq("1_version2_rule_them.all")
    end

    it "writes the rpm spec" do
      project = RpmProject.new
      packager = Rpm.new(project)

      with_packager(packager) do |p|
        p.write_rpm_spec
        file = File.read(p.spec_file)

        file.should match(/Version: #{packager.safe_version}/)
        file.should match(/%description\nFirst line\n\.\nThird line/)
        # assert it populated package scripts
        file.should match(/pre\nfoobar/)
      end
    end
  end
end