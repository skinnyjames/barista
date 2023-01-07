# Barista::Behaviors::Omnibus::Task

The [Barista::Behaviors::Omnibus::Task][] module provides instance methods to a task class that helps with

* Declaring source code archive locations to fetch
* Aggregating licenses and license files from the source code
* Running commands against the source code
* Building the source code to a staging directory to be archived and cached
* Moving the source code to a shared directory to be packaged

The interface of a [Barista::Behaviors::Omnibus::Task][] extends [Barista::Behaviors::Software::Task][] but expects a bit more.

1. In addition to `#build` we must implement a `#configure` method on the task.
1. The initializer expects a [Barista::Behaviors::Omnibus::Project][], with an optional [Barista::Behaviors::Omnibus::CacheCallbacks][]

# Example

A task for building the [zlib compression library](https://zlib.net/) might look like

```crystal
class Zlib < Barista::Task
  include Barista::Behaviors::Omnibus::Task

  @@name = "zlib"

  # This will run after #configure to configure the needed commands on the task
  def build : Nil
    env = with_standard_compiler_flags(with_destdir)

    command("./configure --prefix=#{install_dir}/embedded", env: env)
    command("make", env: env)
    command("make install", env: env)
  end

  # This will run before #build to configure the needed state on the task
  # the Omnibus behavior provides methods to provide this state.
  def configure : Nil
    version("1.2.13")
    source("https://zlib.net/zlib-#{version}.tar.gz"
      sha256: "b3a24de97a8fdbc835b9833169501030b8977031bcb54b3b3ac13740f846ab30")

    # if intending to distribute this software, we can specify the license,
    # as well as any license files present in the source 
    license("Zlib")
    license_file("README")
  end
end
```

!!! info
    
    When this task is instantiated, it will

    1. run `configure` to configure related state on the object

    When this task executes, it will
    
    1. run `build` to save the commands on the object
    1. create the needed source, stage, and install directories
    1. attempt to fetch the task artifacts from the cache if using caching
    1. if the cache retrieval fails
        1. it will attempt to download the source and unpack it
        1. it will execute any commands defined on the task
        1. it will copy any defined license files from the source directory
        1. it will attempt to update the cache with the isolated build artifact if caching
    1. it will move the artifacts to the installation directory if they aren't built there already


Let's unpack what is happening in this task definition.

## Configuring

### Setting a friendly name

```crystal
@@name = "zlib"
```

As per `Barista::Task`, we can set a friendly name as a class variable, which would otherwise be the name of the class.

When this task downloads and unpacks it's source, it will be to `#{project.source_dir}/zlib`.

### Configuring a version and a source url

```crystal
def configure : Nil
  version("1.2.13")
  source("https://zlib.net/zlib-#{version}.tar.gz"
    sha256: "b3a24de97a8fdbc835b9833169501030b8977031bcb54b3b3ac13740f846ab30")
#...
```

`#version` or [Barista::Behaviors::Omnibus::Task#version(val)][] will speak to the version of the software source being built.

!!! warning

    a version is required on non-virtual tasks, as the version will be added to license summary and the manifest.

`#source` or [Barista::Behaviors::Omnibus::Task#source(url,**)][] will configure the network location of the software source being downloaded.

* `#source` passes options to [Barista::Behaviors::Software::Fetchers::Net][] so we can add:
  * a _[md5|sha1|sha256|sha512]_ hash to verify the download is correct.
  * addtional `HTTP::Headers`
  * an `HTTP::Client::TLSContext` 
  * a number of times to `retry` the download
  * an `extension` to download as if the remote url doesn't have one
  * a `strip` depth for unpacking the archive

!!! note  

    `#source` currently only supports remote archives. Git/local sources or non-archive remote files can still be configured inside `#build`

## Configuring a license and any license files

```crystal
license("Zlib")
license_file("README")
```

Here we are declaring the license of this source project, and it's license files.  The license can be referenced into a [license summary](/barista/Barista/Behaviors/Omnibus/LicenseCollector/#Barista::Behaviors::Omnibus::LicenseCollector#write_summary), and the files copied to `#{project.install_dir}/LICENSES`

`#license` or [Barista::Behaviors::Omnibus::Task#license(val)][] represents the license of the project.  For Zlib, the license is [Zlib](https://zlib.net/zlib_license.html)

`#license_file` or [Barista::Behaviors::Omnibus::Task#license_file(val)][] represents a path to the license files from _within_ the source directory.  This method can be called multiple times to specify multiple license files.

## Building

### Populating a predefined hash of environment variables and passing it to commands

```crystal
def build : Nil
  env = with_standard_compiler_flags(with_destdir)

  command("./configure --prefix=#{install_dir}/embedded", env: env)
  command("make", env: env)
  command("make install", env: env)
end
```

`#with_standard_compiler_flags` or [Barista::Behaviors::Omnibus::PlatformEnv#with_standard_compiler_flags(env,opts)][] returns some common compilation, linker, and pkgconfig flags that are specific to the locations defined in the task's project.  

Since Omnibus tasks are typically configuring and building binaries, libraries and shared objects to a custom location, this helps sources reference compilation dependencies during a build.

`#with_destdir` or [Barista::Behaviors::Omnibus::PlatformEnv#with_destdir(env)][] sets the [DESTDIR](https://www.gnu.org/prep/standards/html_node/DESTDIR.html) environment variable to a special staging path if the task is using caching.  This is helpful for isolating the individual artifacts of the source and caching them.

`#command` or [Barista::Behaviors::Omnibus::Task#command(str,chdir,**)][] executes a shell command and emits it's output.  By default it executes it from the source code directory.

* the `chdir` option can be used to run the command from another place.
* the `env` option can be used to specify additional environment variables. 


In the example above we are running commands against the `Zlib` source.

!!! warning

    Note on `#with_destdir` and `--prefix=#{install_dir}/embedded`

    While it is customary for make scripts to honor `DESTDIR`, this is not always the case.  

    In such cases, we can build directly to the `smart_install_dir` directory to be cached.

    ```crystal
    # If using a cache, this will build zlib to 
    # `#{project.barista_dir}/stage/zlib/#{project.install_dir}/embedded
    def build : Nil
      env = with_standard_compiler_flags

      command("./configure --prefix=#{smart_install_dir}/embedded")
      command("make", env: env)
      command("make install", env: env)
    end
    ```

    However, now symbolic links that were configured against the prefix will reference the incorrect paths when they are moved to the 
    project's installation directory.

    We can tell `Barista::Behaviors::Omnibus::Task` to reconstruct these links when syncing in the `configure` method.

    ```crystal
    def configure : Nil
      preserve_symlinks(false)
    end
    ```

## Providing additional runtime state to an Omnibus::Task

Since there is a loose coupling between task instantiation and orchestration, we can change the constructor to provide additional state to the task.  The task will still require a project and any cache callbacks.

```crystal
def initialize(
  project : Barista::Behaviors::Omnibus::Project, 
  callbacks : Barista::Behaviors::Omnibus::CacheCallbacks, 
  @some_extra_custom_state : String
)
  super(project, callbacks)
end
```

## Virtual tasks

If a task is a supporting task that doesn't produce versioned or distributable artifacts, it can be omitted from the license summary and manifest by 
passing `true` to [Barista::Behaviors::Omnibus::Task#virtual(val)][]

## More information

For more information on what can be done in an Omnibus task, please refer to the [API docs](/barista/Barista/Behaviors/Omnibus/Task)