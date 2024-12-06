# frozen_string_literal: true

module Faker
  class App < Base
    class << self
      ##
      # Produces an app name.
      #
      # @return [String]
      #
      # @example
      #   Faker::App.name #=> "Treeflex"
      #
      # @faker.version 1.4.3
      def name
        fetch('app.name')
      end

      ##
      # Produces a version string.
      #
      # @return [String]
      #
      # @example
      #   Faker::App.version #=> "1.85"
      #
      # @faker.version 1.4.3
      def version
        parse('app.version')
      end

      ##
      # Produces the name of an app's author.
      #
      # @return [String]
      #
      # @example
      #   Faker::App.author #=> "Daphne Swift"
      #
      # @faker.version 1.4.3
      def author
        parse('app.author')
      end

      # rubocop:disable Metrics/ParameterLists

      ##
      # Produces a String representing a semantic version identifier.
      #
      # @param major [Integer, Range] An integer to use or a range to pick the integer from.
      # @param minor [Integer, Range] An integer to use or a range to pick the integer from.
      # @param patch [Integer, Range] An integer to use or a range to pick the integer from.
      # @return [String]
      #
      # @example
      #   Faker::App.semantic_version #=> "3.2.5"
      # @example
      #   Faker::App.semantic_version(major: 42) #=> "42.5.2"
      # @example
      #   Faker::App.semantic_version(minor: 100..101) #=> "42.100.4"
      # @example
      #   Faker::App.semantic_version(patch: 5..6) #=> "7.2.6"
      #
      # @faker.version 1.4.3
      def semantic_version(legacy_major = NOT_GIVEN, legacy_minor = NOT_GIVEN, legacy_patch = NOT_GIVEN, major: 0..9, minor: 0..9, patch: 1..9)
        warn_for_deprecated_arguments do |keywords|
          keywords << :major if legacy_major != NOT_GIVEN
          keywords << :minor if legacy_minor != NOT_GIVEN
          keywords << :patch if legacy_patch != NOT_GIVEN
        end

        [major, minor, patch].map { |chunk| sample(Array(chunk)) }.join('.')
      end
      # rubocop:enable Metrics/ParameterLists
    end
  end
end
