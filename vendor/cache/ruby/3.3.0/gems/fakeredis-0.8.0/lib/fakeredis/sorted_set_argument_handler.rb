module FakeRedis
  # Takes in the variable length array of arguments for a zinterstore/zunionstore method
  # and parses them into a few attributes for the method to access.
  #
  # Handles throwing errors for various scenarios (matches redis):
  #   * Custom weights specified, but not enough or too many given
  #   * Invalid aggregate value given
  #   * Multiple aggregate values given
  class SortedSetArgumentHandler
    # [Symbol] The aggregate method to use for the output values. One of %w(sum min max) expected
    attr_reader :aggregate
    # [Integer] Number of keys in the argument list
    attr_accessor :number_of_keys
    # [Array] The actual keys in the argument list
    attr_accessor :keys
    # [Array] integers for weighting the values of each key - one number per key expected
    attr_accessor :weights

    # Used internally
    attr_accessor :type

    # Expects all the argments for the method to be passed as an array
    def initialize args
      # Pull out known lengths of data
      self.number_of_keys = args.shift
      self.keys = args.shift(number_of_keys)
      # Handle the variable lengths of data (WEIGHTS/AGGREGATE)
      args.inject(self) {|handler, item| handler.handle(item) }

      # Defaults for unspecified things
      self.weights ||= Array.new(number_of_keys) { 1 }
      self.aggregate ||= :sum

      # Validate values
      raise(Redis::CommandError, "ERR syntax error") unless weights.size == number_of_keys
      raise(Redis::CommandError, "ERR syntax error") unless [:min, :max, :sum].include?(aggregate)
    end

    # Only allows assigning a value *once* - raises Redis::CommandError if a second is given
    def aggregate=(str)
      raise(Redis::CommandError, "ERR syntax error") if (defined?(@aggregate) && @aggregate)
      @aggregate = str.to_s.downcase.to_sym
    end

    # Decides how to handle an item, depending on where we are in the arguments
    def handle(item)
      case item
      when "WEIGHTS"
        self.type = :weights
        self.weights = []
      when "AGGREGATE"
        self.type = :aggregate
      when nil
        # This should never be called, raise a syntax error if we manage to hit it
        raise(Redis::CommandError, "ERR syntax error")
      else
        send "handle_#{type}", item
      end
      self
    end

    def handle_weights(item)
      self.weights << item
    end

    def handle_aggregate(item)
      self.aggregate = item
    end

    def inject_block
      lambda { |handler, item| handler.handle(item) }
    end
  end
end
