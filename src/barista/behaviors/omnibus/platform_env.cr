module Barista
  module Behaviors
    module Omnibus
      module PlatformEnv
        def with_standard_compiler_flags(env = {} of String => String, opts = {} of String => String) : Hash(String, String)
          compiler_flags = begin
            {
              "LDFLAGS" => "-Wl,-rpath,#{install_dir}/embedded/lib -L#{install_dir}/embedded/lib",
              "CFLAGS" => "-I#{install_dir}/embedded/include -O3 -D_FORTIFY_SOURCE=2 -fstack-protector"
            }
          end

          extra_linker_flags = {
            "LD_RUN_PATH" => "#{install_dir}/embedded/lib"
          }

          env
          .merge(compiler_flags)
          .merge(extra_linker_flags)
          .merge({ "PKG_CONFIG_PATH" => "#{install_dir}/embedded/lib/pkgconfig" })
          .merge({ "CXXFLAGS" => compiler_flags["CFLAGS"] })
          .merge({ "CPPFLAGS" => compiler_flags["CFLAGS"] })
        end

        def with_embedded_path(env = {} of String => String) : Hash(String, String)
          paths = ["#{install_dir}/bin", "#{install_dir}/embedded/bin"]
          path_value = prepend_path(paths)
          env.merge({ path_key => path_value })
        end

        private def prepend_path(paths) : String
          paths << ENV[path_key]

          paths.join(":")
        end

        private def path_key
          "PATH"
        end
      end
    end
  end
end
