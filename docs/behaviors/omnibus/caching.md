# Caching

Caching in Omnibus builds are performed via [Barista::Behaviors::Omnibus::CacheCallbacks][]

These callbacks allow the build to perform agnostic caching strategies.  They can be configured to use a file system, network, or other strategies.

It works by providing executable blocks to `#fetch` and `#update` that should update and fetch artifacts to and from the cache.

!!! note

    As Barista is not aware of the caching strategy, the callback blocks need to return a boolean to note if the block succeeded or failed

!!! info 
  
    Caching is not on by default.
    
    To employ caching, pass `true` to `Barista::Behaviors::Omnibus::Project#cache`, and callbacks to each task when initializing them.

## Example (Filesystem cache)

```crystal
callbacks = Barista::Behaviors::Omnibus::CacheCallbacks.new

# Assuming the cache is located at `/cache`
# Copy the cached archive to a temporary directory
# and unpack it to the staging directory
callbacks.fetch do |cacher|
  dir = Dir.tempdir
  cache_path = File.join("/cache", cacher.filename)
  begin
    if File.exists?(cache_path)
      FileUtils.cp_r(cache_path, dir)
      cacher.unpack(File.join(dir, cacher.filename))
    else
      false
    end
  rescue ex
    false
  end
end

# ensure the cache directory exists
# and copy the archive to it
# `path` points to the staged aritfact archive
callbacks.update do |task, path|
  FileUtils.mkdir_p("/cache")
  FileUtils.cp(path, "/cache/#{task.tag}.tar.gz")
  true
end
```

!!! note

    The artifact will always be a `.tar.gz`.

    `cacher.filename` is the same as `task.tag`, except with the `.tar.gz` extension. 

## Barista::Behaviors::Omnibus::Cacher

[Barista::Behaviors::Omnibus::Cacher][] is a helper object that is passed as a block parameter to the `fetch` calllback.

It's primary export is an `unpack` method, which takes a path to an archived artifact, and extracts it to the appropriate directory.

## Cache busting

The cache tag (and `cacher.filename`) is made up of the following

* A custom prefix declared on the project (defaults to the project name)
* The name of the task
* The shasum of the task

[Barista::Behaviors::Omnibus::Project#cache_tag_prefix][] can be set to configure the cache name according to project, platform, architecture, or a custom behavior.

[Barista::Behaviors::Omnibus::Task#shasum][] returns a hexdigest of the task.  This digest is computed from

* The `version` of the task (if applicable)
* The `source` URI of the task
* The license and any license files for the task
* The digest of all the commands configured on the task
* The project's shasum
* The shasum of all the task's upstream dependencies

!!! info

    By including the `shasum` of a task's upstream dependencies in the cache tag, we can ensure that the task 
    will be rebuilt if an upstream changes, without blocking any other tasks whose upstreams did not change.


## Uncached tasks

It is common to not cache certain tasks.  To avoid using a cache for a task, pass `false` to [Barista::Behaviors::Omnibus::Task#cache(val)][]