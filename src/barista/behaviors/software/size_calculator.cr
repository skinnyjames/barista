require "big"

module Barista
  module Behaviors
    module Software
      # Concurrently calculates the size of a given list of paths
      class SizeCalculator
        getter :paths, :workers

        # takes a number of workers to use when performing calculations
        # and a list of paths to calculate the size for.
        def initialize(@workers : Int32, @paths : Array(String) = [] of String)
        end

        def execute
          if paths.size <= workers || workers.zero?
            slice_size = BigInt.new(paths.size)
          else
            slice_size = (BigInt.new(paths.size) / workers).round(3).to_big_i
          end

          path_arrs = paths.each_slice(slice_size).to_a
          sum_channel = Channel(BigInt).new

          path_arrs.map do |pths|
            spawn do
              total = pths.reduce(BigInt.new) do |size, p|
                unless File.directory?(p) || File.symlink?(p)
                  size += File.size(p)
                end

                size
              end

              sum_channel.send(total)
            end
          end

          sum = BigInt.new(0)
          path_arrs.size.times do
            sum += sum_channel.receive
          end

          sum / 1024
        end
      end
    end
  end
end
