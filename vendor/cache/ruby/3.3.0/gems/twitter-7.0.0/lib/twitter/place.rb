require 'memoizable'
require 'twitter/identity'

module Twitter
  class Place < Twitter::Identity
    include Memoizable

    # @return [Hash]
    attr_reader :attributes
    # @return [String]
    attr_reader :country, :full_name, :name
    alias woe_id id
    alias woeid id
    object_attr_reader :GeoFactory, :bounding_box
    object_attr_reader :Place, :contained_within
    alias contained? contained_within?
    uri_attr_reader :uri

    # Initializes a new place
    #
    # @param attrs [Hash]
    # @raise [ArgumentError] Error raised when supplied argument is missing a :woeid key.
    # @return [Twitter::Place]
    def initialize(attrs = {})
      attrs[:id] ||= attrs.fetch(:woeid)
      super
    end

    # @return [String]
    def country_code
      @attrs[:country_code] || @attrs[:countryCode]
    end
    memoize :country_code

    # @return [Integer]
    def parent_id
      @attrs[:parentid]
    end
    memoize :parent_id

    # @return [String]
    def place_type
      @attrs[:place_type] || @attrs[:placeType] && @attrs[:placeType][:name]
    end
    memoize :place_type
  end
end
