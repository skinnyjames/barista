@[Project(Coffeeshop)]
class OpenSSLTask < Barista::Task
  include Barista::Behaviors::Omnibus::Task

  @@name = "openssl"

  dependency CaCerts

  def initialize(@project : Barista::Behaviors::Omnibus::Project)
    super(project)
  end

  def build : Nil
    env = with_standard_compiler_flags(with_embedded_path)

    cmd = String.build do |io|
      io << "./config disable-gost "
      io << "--prefix=#{install_dir}/embedded "
      io << "no-comp "
      io << "no-idea no-mdc2 no-rc5 no-ssl2 no-ssl3 no-zlib shared "
      io << env["CFLAGS"]
      io << " "
      io << env["LDFLAGS"]
    end
    
    command(cmd, env: env)
    command("make depend", env: env)
    command("make", env: env)

    command("make install_sw", env: env)
    command("make install_ssldirs", env: env)
  end

  def configure : Nil
    version("1.1.1")
    source("https://ftp.openssl.org/source/old/#{version}/openssl-#{version}l.tar.gz")
  end
end
