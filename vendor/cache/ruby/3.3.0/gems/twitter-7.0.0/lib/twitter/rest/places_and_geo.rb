require 'twitter/geo_results'
require 'twitter/place'
require 'twitter/rest/utils'

module Twitter
  module REST
    module PlacesAndGeo
      include Twitter::REST::Utils

      # Returns all the information about a known place
      #
      # @see https://dev.twitter.com/rest/reference/get/geo/id/:place_id
      # @rate_limited Yes
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @param place_id [String] A place in the world. These IDs can be retrieved from {Twitter::REST::PlacesAndGeo#reverse_geocode}.
      # @param options [Hash] A customizable set of options.
      # @return [Twitter::Place] The requested place.
      def place(place_id, options = {})
        perform_get_with_object("/1.1/geo/id/#{place_id}.json", options, Twitter::Place)
      end

      # Searches for up to 20 places that can be used as a place_id
      #
      # @see https://dev.twitter.com/rest/reference/get/geo/reverse_geocode
      # @note This request is an informative call and will deliver generalized results about geography.
      # @rate_limited Yes
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @param options [Hash] A customizable set of options.
      # @option options [Float] :lat The latitude to search around. This option will be ignored unless it is inside the range -90.0 to +90.0 (North is positive) inclusive. It will also be ignored if there isn't a corresponding :long option.
      # @option options [Float] :long The longitude to search around. The valid range for longitude is -180.0 to +180.0 (East is positive) inclusive. This option will be ignored if outside that range, if it is not a number, if geo_enabled is disabled, or if there not a corresponding :lat option.
      # @option options [String] :accuracy ('0m') A hint on the "region" in which to search. If a number, then this is a radius in meters, but it can also take a string that is suffixed with ft to specify feet. If coming from a device, in practice, this value is whatever accuracy the device has measuring its location (whether it be coming from a GPS, WiFi triangulation, etc.).
      # @option options [String] :granularity ('neighborhood') This is the minimal granularity of place types to return and must be one of: 'poi', 'neighborhood', 'city', 'admin' or 'country'.
      # @option options [Integer] :max_results A hint as to the number of results to return. This does not guarantee that the number of results returned will equal max_results, but instead informs how many "nearby" results to return. Ideally, only pass in the number of places you intend to display to the user here.
      # @return [Array<Twitter::Place>]
      def reverse_geocode(options = {})
        perform_get_with_object('/1.1/geo/reverse_geocode.json', options, Twitter::GeoResults)
      end

      # Search for places that can be attached to a {Twitter::REST::Tweets#update}
      #
      # @see https://dev.twitter.com/rest/reference/get/geo/search
      # @rate_limited Yes
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @param options [Hash] A customizable set of options.
      # @option options [Float] :lat The latitude to search around. This option will be ignored unless it is inside the range -90.0 to +90.0 (North is positive) inclusive. It will also be ignored if there isn't a corresponding :long option.
      # @option options [Float] :long The longitude to search around. The valid range for longitude is -180.0 to +180.0 (East is positive) inclusive. This option will be ignored if outside that range, if it is not a number, if geo_enabled is disabled, or if there not a corresponding :lat option.
      # @option options [String] :query Free-form text to match against while executing a geo-based query, best suited for finding nearby locations by name.
      # @option options [String] :ip An IP address. Used when attempting to fix geolocation based off of the user's IP address.
      # @option options [String] :granularity ('neighborhood') This is the minimal granularity of place types to return and must be one of: 'poi', 'neighborhood', 'city', 'admin' or 'country'.
      # @option options [String] :accuracy ('0m') A hint on the "region" in which to search. If a number, then this is a radius in meters, but it can also take a string that is suffixed with ft to specify feet. If coming from a device, in practice, this value is whatever accuracy the device has measuring its location (whether it be coming from a GPS, WiFi triangulation, etc.).
      # @option options [Integer] :max_results A hint as to the number of results to return. This does not guarantee that the number of results returned will equal max_results, but instead informs how many "nearby" results to return. Ideally, only pass in the number of places you intend to display to the user here.
      # @option options [String] :contained_within This is the place_id which you would like to restrict the search results to. Setting this value means only places within the given place_id will be found.
      # @option options [String] :"attribute:street_address" This option searches for places which have this given street address. There are other well-known and application-specific attributes available. Custom attributes are also permitted.
      # @return [Array<Twitter::Place>]
      def geo_search(options = {})
        perform_get_with_object('/1.1/geo/search.json', options, Twitter::GeoResults)
      end
      alias places_nearby geo_search

      # Locates places near the given coordinates which are similar in name
      #
      # @see https://dev.twitter.com/rest/reference/get/geo/similar_places
      # @note Conceptually, you would use this method to get a list of known places to choose from first. Then, if the desired place doesn't exist, make a request to {Twitter::REST::PlacesAndGeo#place} to create a new one. The token contained in the response is the token necessary to create a new place.
      # @rate_limited Yes
      # @authentication Requires user context
      # @raise [Twitter::Error::Unauthorized] Error raised when supplied user credentials are not valid.
      # @param options [Hash] A customizable set of options.
      # @option options [Float] :lat The latitude to search around. This option will be ignored unless it is inside the range -90.0 to +90.0 (North is positive) inclusive. It will also be ignored if there isn't a corresponding :long option.
      # @option options [Float] :long The longitude to search around. The valid range for longitude is -180.0 to +180.0 (East is positive) inclusive. This option will be ignored if outside that range, if it is not a number, if geo_enabled is disabled, or if there not a corresponding :lat option.
      # @option options [String] :name The name a place is known as.
      # @option options [String] :contained_within This is the place_id which you would like to restrict the search results to. Setting this value means only places within the given place_id will be found.
      # @option options [String] :"attribute:street_address" This option searches for places which have this given street address. There are other well-known and application-specific attributes available. Custom attributes are also permitted.
      # @return [Array<Twitter::Place>]
      def similar_places(options = {})
        perform_get_with_object('/1.1/geo/similar_places.json', options, Twitter::GeoResults)
      end
      alias places_similar similar_places
    end
  end
end
