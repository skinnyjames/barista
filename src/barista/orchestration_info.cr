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
      @active_sequences : Array(Tuple(String, String))
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
        "Active Sequences #{format(format_tuples(active_sequences))}"
      ].join("\n")
    end

    private def format(arr)
      arr.empty? ? "None" : arr.join(", ")
    end

    private def format_tuples(arr)
      arr.map do |k, v|
        "{ #{k}, #{v} }"
      end
    end
  end

  struct Sequences
    getter :sequences

    delegate(
      :empty?,
      :size,
      :map,
      :each,
      to: @sequences
    )

    def initialize(@sequences = [] of Tuple(String, String)); end

    def includes_task?(task : Barista::Task)
      sequences.any? do |sequence, name|
        task.sequences.includes?(sequence)
      end
    end

    def <<(task : Barista::Task)
      task.sequences.each do |sequence|
        sequences << { sequence, task.name }
      end
    end

    def remove(task : Barista::Task)
      sequences.reject! do |sequence, _|
        task.sequences.includes?(sequence)
      end
    end
  end
end