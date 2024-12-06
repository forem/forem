# frozen_string_literal: true

module Sources
  # Support code to allow updating subdivision data from the Unicode CLDR repository
  module Local
    # Loader for locally-cached data, to allow merging Unicode CLDR data with existing local data
    class CachedLoader
      attr_reader :klass

      def initialize(klass)
        @klass = klass
        @loaded_countries = {}
      end

      def from_cache(country_code)
        @loaded_countries[country_code]
      end

      def load(country_code)
        if (data = from_cache(country_code))
          data
        else
          @loaded_countries[country_code] = klass.load(country_code)
        end
      end

      def save(country_code, data)
        klass.new(country_code).save(data)
      end
    end
  end
end
