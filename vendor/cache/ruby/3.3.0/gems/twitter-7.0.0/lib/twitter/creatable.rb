require 'time'
require 'memoizable'

module Twitter
  module Creatable
    include Memoizable

    # Time when the object was created on Twitter
    #
    # @return [Time]
    def created_at
      time = @attrs[:created_at]
      return if time.nil?

      time = Time.parse(time) unless time.is_a?(Time)
      time.utc
    end
    memoize :created_at

    # @return [Boolean]
    def created?
      !!@attrs[:created_at]
    end
    memoize :created?
  end
end
