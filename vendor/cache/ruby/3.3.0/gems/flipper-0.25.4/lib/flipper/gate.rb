module Flipper
  class Gate
    # Public
    def initialize(options = {})
    end

    # Public: The name of the gate. Implemented in subclass.
    def name
      raise 'Not implemented'
    end

    # Private: Name converted to value safe for adapter. Implemented in subclass.
    def key
      raise 'Not implemented'
    end

    def data_type
      raise 'Not implemented'
    end

    def enabled?(_value)
      raise 'Not implemented'
    end

    # Internal: Check if a gate is open for a thing. Implemented in subclass.
    #
    # Returns true if gate open for thing, false if not.
    def open?(_thing, _value, _options = {})
      false
    end

    # Internal: Check if a gate is protects a thing. Implemented in subclass.
    #
    # Returns true if gate protects thing, false if not.
    def protects?(_thing)
      false
    end

    # Internal: Allows gate to wrap thing using one of the supported flipper
    # types so adapters always get something that responds to value.
    def wrap(thing)
      thing
    end

    # Public: Pretty string version for debugging.
    def inspect
      attributes = [
        "name=#{name.inspect}",
        "key=#{key.inspect}",
        "data_type=#{data_type.inspect}",
      ]
      "#<#{self.class.name}:#{object_id} #{attributes.join(', ')}>"
    end
  end
end

require 'flipper/gates/actor'
require 'flipper/gates/boolean'
require 'flipper/gates/group'
require 'flipper/gates/percentage_of_actors'
require 'flipper/gates/percentage_of_time'
