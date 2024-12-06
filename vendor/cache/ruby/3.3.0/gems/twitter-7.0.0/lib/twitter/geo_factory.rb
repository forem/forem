require 'twitter/factory'
require 'twitter/geo/point'
require 'twitter/geo/polygon'

module Twitter
  class GeoFactory < Twitter::Factory
    class << self
      # Construct a new geo object
      #
      # @param attrs [Hash]
      # @raise [IndexError] Error raised when supplied argument is missing a :type key.
      # @return [Twitter::Geo]
      def new(attrs = {})
        super(:type, Geo, attrs)
      end
    end
  end
end
