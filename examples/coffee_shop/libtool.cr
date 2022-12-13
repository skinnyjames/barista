@[Project(Coffeeshop)]
class LibTool < Barista::Task
  include Barista::Behaviors::Omnibus::Task

  @@name = "libtool"

  dependency ConfigGuess
  
  def initialize(@project : Barista::Behaviors::Omnibus::Project)
    super(project)
  end

  def build : Nil
    env = with_standard_compiler_flags(with_embedded_path)

    command("./configure --prefix=#{install_dir}/embedded", env: env)
    command("make", env: env)
    command("make install", env: env)
  end
  
  def configure : Nil
    version("2.4.6")
    source( "https://ftp.gnu.org/gnu/libtool/libtool-#{version}.tar.gz")
  end
end
