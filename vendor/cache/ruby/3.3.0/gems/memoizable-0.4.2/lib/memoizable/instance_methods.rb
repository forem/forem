# encoding: utf-8

module Memoizable

  # Methods mixed in to memoizable instances
  module InstanceMethods

    # Freeze the object
    #
    # @example
    #   object.freeze  # object is now frozen
    #
    # @return [Object]
    #
    # @api public
    def freeze
      memoized_method_cache  # initialize method cache
      super
    end

    # Sets a memoized value for a method
    #
    # @example
    #   object.memoize(hash: 12345)
    #
    # @param [Hash{Symbol => Object}] data
    #   the data to memoize
    #
    # @return [self]
    #
    # @api public
    def memoize(data)
      data.each { |name, value| memoized_method_cache[name] = value }
      self
    end

  private

    # The memoized method results
    #
    # @return [Hash]
    #
    # @api private
    def memoized_method_cache
      @_memoized_method_cache ||= Memory.new
    end

  end # InstanceMethods
end # Memoizable
