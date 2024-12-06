# frozen_string_literal: true

module ISO3166
  class Country
    def mongoize
      ISO3166::Country.mongoize(self)
    end

    class << self
      # Convert an +ISO3166::Country+ to the data that is stored by Mongoid.
      def mongoize(country)
        if country.is_a?(self) && !country.data.nil?
          country.alpha2
        elsif send(:valid_alpha2?, country)
          new(country).alpha2
        end
      end

      # Get the object as it was stored with Mongoid, and instantiate an +ISO3166::Country+.
      def demongoize(alpha2)
        new(alpha2)
      end

      # Convert an +ISO3166::Country+ to the data that is stored by Mongoid.
      def evolve(country)
        mongoize(country)
      end

      private

      def valid_alpha2?(country)
        country.is_a?(String) && !ISO3166::Country.new(country).nil?
      end
    end
  end
end
