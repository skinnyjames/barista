@[Project(Coffeeshop)]
class LibEvent < Barista::Task
  include Barista::Behaviors::Omnibus::Task
  
  @@name = "libevent"

  dependency LibTool
  dependency OpenSSLTask

  def initialize(@project : Barista::Behaviors::Omnibus::Project)
    super(project)
  end

  def build : Nil
    env = with_standard_compiler_flags(with_embedded_path)

    command("./autogen.sh", env: env)
    command("./configure --prefix=#{install_dir}/embedded", env: env)
    command("make", env: env)
    command("make install", env: env)
  end

  def configure : Nil
    version("2.1.12")
    source("https://github.com/libevent/libevent/releases/download/release-#{version}-stable/libevent-#{version}-stable.tar.gz")
  end
end
