@[Barista::BelongsTo(Coffeeshop)]
class ConfigGuess < Barista::Task
  include Barista::Behaviors::Omnibus::Task
  
  @@name = "config-guess"

  def initialize(@project : Barista::Behaviors::Omnibus::Project); 
    super(project)
  end

  def build : Nil
    config_guess_dir = File.join(install_dir, "embedded", "lib", "config_guess")

    mkdir(config_guess_dir, parents: true)
    copy("config.guess", "#{config_guess_dir}/config.guess")
    copy("config.sub", "#{config_guess_dir}/config.sub")
  end

  def configure : Nil
    version("12.2.0")
    source("https://github.com/gcc-mirror/gcc/archive/refs/tags/releases/gcc-#{version}.tar.gz")
  end
end
