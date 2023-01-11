module Barista
  # Describes the orchestration state
  #
  # Passed to the on_unblocked callback
  struct OrchestrationInfo
    getter :unblocked, :blocked, :building, :built, :active_sequences

    def initialize(*,
      @unblocked : Array(String),
      @blocked : Array(String),
      @building : Array(String),
      @built : Array(String),
      @active_sequences : Array(String)
    )
    end

    def to_s(io : IO)
      io << to_s
    end
    
    def to_s
      [
        "Unblocked #{format(unblocked)}",
        "Blocked  #{format(blocked)}",
        "Building #{format(building)}",
        "Built #{format(built)}",
        "Active Sequences #{format(active_sequences)}"
      ].join("\n")
    end

    private def format(arr)
      arr.empty? ? "None" : arr.join(", ")
    end
  end

  # A fiber safe class to track
  # sequence state
  struct SafeSequences
    getter :sequences, :mutex

    def initialize(@mutex : Mutex, @sequences : Array(String) = [] of String); end

    def any?(&block : String -> Bool)
      mutex.synchronize do
        sequences.any? do |sequence|
          block.call(sequence)
        end
      end
    end

    def <<(task : Barista::Task)
      mutex.synchronize do
        sequences.concat(task.sequences)
      end
    end

    def remove(task : Barista::Task)
      mutex.synchronize do
        sequences.reject! do |sequence|
          task.sequences.includes?(sequence)
        end
      end
    end

    def empty?
      mutex.synchronize do
        sequences.empty?
      end
    end

    def to_a : Array(String)
      mutex.synchronize do
        sequences
      end
    end
  end
end