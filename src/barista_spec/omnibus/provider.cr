require "yaml"
require "http"
require "file_utils"
require "../../barista"
require "./provider/syntax"

class BaristaSpec::Omnibus::Provider
  include FileUtils
  
  @env = {} of String => String
  @allowed = [] of Tuple(String, String)

  getter :env, :provider, :path, :allowed

  def initialize(@path : String, file : String)
    @provider = Syntax::Provider.from_yaml(File.read(file))
  end

  def prepare
    mkdir_p("#{path}/system")

    Syntax::System::DEFAULT_ALLOWS.each do |allowed|
      allow_binary(allowed)
    end

    provider.system.try do |system|
      system.binaries.try do |binaries|
        binaries.each do |binary|
          write_system_binary(binary)
        end
      end

      system.allows.try do |binaries|
        binaries.each do |binary|
          allow_binary(binary)
        end
      end
    end

    allowed.each do |realpath, command|
      ln_s(realpath, "#{system_path}/#{command}")
    end

    update_permissions(system_path)
      
    @env = reset_env
  end

  def prepare(task : Barista::Behaviors::Omnibus::Task)
    begin
      mutate_task(task)
      mkdir_p(task.smart_install_dir)

      provider.get_task(task.name).try do |defn|
        mkdir_p(task_path(task))

        defn.provides.try do |provides|
          prepare_providers(provides, task)
        end

        defn.installs.try do |installs|
          prepare_installs(installs, task)
        end

        defn.mocks.try do |mocks|
          prepare_mocks(mocks, task)
        end
      end

      update_permissions(task_path(task))
      update_permissions(task.install_dir)

      mock_task_source(task)
    rescue ex
      puts "Error in Provider#prepare for #{task.name}> raised #{ex}"
      exit 1
    end
  end

  def update_permissions(path)
    Dir.glob("#{path}/**/*").each do |file|
      if File.file?(file) && !File.symlink?(file)
        File.chmod(file, File::Permissions.new(0o755))
      end
    end
  end

  def mutate_task(task)
    if src = task.source
      if src.is_a?(Barista::Behaviors::Software::Fetchers::Net)
        task.source(src.location, extension: src.extension)
      end
    end

    task.commands.reject!(&.is_a?(Barista::Behaviors::Software::Commands::Patch))
  end

  def prepare_providers(defn, task)
    files = [
      *(defn.binaries || [] of Syntax::Binary),
      *(defn.files || [] of Syntax::File)
    ]

    files.each do |file|
      File.write(file_path(task, file.name), file.content)
    end
  end

  def prepare_installs(defn, task)
    files = [
      *(defn.binaries || [] of Syntax::Binary),
      *(defn.files || [] of Syntax::File)
    ]

    files.each do |file|
      path = Path.new("#{task.smart_install_dir}/#{file.name}")
      mkdir_p(path.dirname)
      File.write(path.to_s, file.content)
    end
  end

  def prepare_mocks(defn, task)
    defn.each do |mock|
      case mock
      when Syntax::ApiMock
        io = IO::Memory.new(mock.content)

        WebMock.stub(:get, Regex.new(mock.url)).to_return(status: 200, body_io: io)
      when Syntax::FileMock
        mkdir_p(task.source_dir)
        File.write("#{task.source_dir}/#{mock.name}", mock.content)
      end
    end
  end

  def mock_task_source(task)
    task.source.try do |src|
      if src.is_a?(Barista::Behaviors::Software::Fetchers::Net)
        if Dir.exists?(task_path(task))
          gzip_task_path(task)

          WebMock.stub(:get, src.uri.to_s).to_return do |request|
            headers = HTTP::Headers.new.merge!({ "Content-Type" => "application/gzip", "Content-Encoding" => "gzip" })
            HTTP::Client::Response.new(200, body_io: File.open("#{task_path(task)}.tar.gz"), headers: headers)
          end
        end
      end
    end
  end

  def reset_env
    ENV.keys.each do |key|
      env[key] = ENV[key]
      ENV.delete(key)
    end

    ENV["PATH"] = "#{path}/system"

    env
  end

  def restore_env
    @env.try do |env|
      env.keys.each do |key|
        ENV[key] = env[key]
      end
    end
  end

  private def write_system_binary(binary : Syntax::Binary)
    File.write("#{system_path}/#{binary.name}", binary.content)
  end

  private def allow_binary(binary : Syntax::Binary)
    allow_binary(binary.name)
  end

  private def allow_binary(binary : String)
    binary_path =  which(binary)
    raise "Binary #{binary} not found" if binary_path =~ /not found/

    allowed << { binary_path, binary }
  end

  private def which(name)
    run_command("which", [name])
  end

  private def run_command(command, args, **opts)
    output = IO::Memory.new
    error = IO::Memory.new
    status = Process.run(command, args, **opts.merge({ output: output, error: error }))

    raise "TaskHelper command failed! #{error.gets}" unless status.success?

    output.to_s.strip
  end

  private def gzip_task_path(task)
    run_command("tar", ["-czvf", "#{task.name}.tar.gz", task.name], shell: true ,env: env, chdir: path)
  end

  private def file_path(task, name)
    path = Path.new(task_path(task), name)

    mkdir_p(path.dirname) unless Dir.exists?(path.dirname)

    path.to_s
  end

  private def system_path
    File.join(path, "system")
  end

  private def task_path(task)
    File.join(path, task.name)
  end
end
