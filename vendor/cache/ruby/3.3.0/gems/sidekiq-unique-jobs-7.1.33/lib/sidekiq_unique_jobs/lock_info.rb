# frozen_string_literal: true

module SidekiqUniqueJobs
  #
  # Class Info provides information about a lock
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  #
  class LockInfo < Redis::String
    #
    # Returns the value for this key as a hash
    #
    #
    # @return [Hash]
    #
    def value
      @value ||= load_json(super)
    end

    #
    # Check if this redis string is blank
    #
    #
    # @return [Boolean]
    #
    def none?
      value.nil? || value.empty?
    end

    #
    # Check if this redis string has a value
    #
    #
    # @return [Boolean]
    #
    def present?
      !none?
    end

    #
    # Quick access to the hash members for the value
    #
    # @param [String, Symbol] key the key who's value to retrieve
    #
    # @return [Object]
    #
    def [](key)
      value[key.to_s] if value.is_a?(Hash)
    end

    #
    # Writes the lock info to redis
    #
    # @param [Hash] obj the information to store at key
    #
    # @return [Hash]
    #
    def set(obj, pipeline = nil)
      return unless SidekiqUniqueJobs.config.lock_info
      raise InvalidArgument, "argument `obj` (#{obj}) needs to be a hash" unless obj.is_a?(Hash)

      json = dump_json(obj)
      @value = load_json(json)
      super(json, pipeline)
      value
    end
  end
end
