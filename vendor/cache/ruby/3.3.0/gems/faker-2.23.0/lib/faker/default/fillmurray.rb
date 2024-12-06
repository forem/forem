# frozen_string_literal: true

module Faker
  class Fillmurray < Base
    class << self
      # rubocop:disable Metrics/ParameterLists

      ##
      # Produces the URL of an image from Fill Murray, a site which hosts
      # exclusively photographs of actor Bill Murray.
      #
      # @param grayscale [Boolean] Whether to return a grayscale image.
      # @param width [Integer] The iamage width.
      # @param height [Integer] The image height.
      # @return [String]
      #
      # @example
      #   Faker::Fillmurray.image #=> "https://www.fillmurray.com/300/300"
      #
      # @example
      #   Faker::Fillmurray.image(grayscale: true)
      #     #=> "https://fillmurray.com/g/300/300"
      #
      # @example
      #   Faker::Fillmurray.image(grayscale: false, width: 200, height: 400)
      #     #=> "https://fillmurray.com/200/400"
      #
      # @faker.version 1.7.1
      def image(legacy_grayscale = NOT_GIVEN, legacy_width = NOT_GIVEN, legacy_height = NOT_GIVEN, grayscale: false, width: 200, height: 200)
        warn_for_deprecated_arguments do |keywords|
          keywords << :grayscale if legacy_grayscale != NOT_GIVEN
          keywords << :width if legacy_width != NOT_GIVEN
          keywords << :height if legacy_height != NOT_GIVEN
        end

        raise ArgumentError, 'Width should be a number' unless width.to_s =~ /^\d+$/
        raise ArgumentError, 'Height should be a number' unless height.to_s =~ /^\d+$/
        raise ArgumentError, 'Grayscale should be a boolean' unless [true, false].include?(grayscale)

        "https://www.fillmurray.com#{'/g' if grayscale == true}/#{width}/#{height}"
      end
      # rubocop:enable Metrics/ParameterLists
    end
  end
end
