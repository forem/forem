# frozen_string_literal: true

module BetterHtml
  module TestHelper
    class SafetyError < InterpolatorError
      attr_reader :location

      def initialize(message, location:)
        @location = location
        super(message)
      end
    end
  end
end
