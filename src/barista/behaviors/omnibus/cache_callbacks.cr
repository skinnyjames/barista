module Barista
  module Behaviors
    module Omnibus
      # Callbacks to specify how to update and restore the cache
      # when building
      struct CacheCallbacks
        @@fetch : Proc(Barista::Behaviors::Omnibus::Cacher, Bool)? = nil
        @@update : Proc(Barista::Behaviors::Omnibus::Task, String, Bool)? = nil

        # Takes a block with a `CacheInfo` parameter
        # to define how the artifact for a given task is fetched
        #
        # Return `true` if the fetch was successfull.
        # Return `false` if the fetch failed.
        def fetch(&block : Barista::Behaviors::Omnibus::Cacher -> Bool)
          @@fetch = block
        end

        def fetch
          @@fetch
        end

        # Takes a block with a `Task` and the Path where the compressed artifact
        # currently resides
        #
        # Return `true` if the update was successfull.
        # Return `false` if the update failed.
        def update(&block : Barista::Behaviors::Omnibus::Task, String -> Bool)
          @@update = block
        end

        def update
          @@update
        end
      end
    end
  end
end
