# frozen_string_literal: true

module Solargraph
  class TypeChecker
    # A problem reported by TypeChecker.
    #
    class Problem
      # @return [Solargraph::Location]
      attr_reader :location

      # @return [String]
      attr_reader :message

      # @return [Pin::Base]
      attr_reader :pin

      # @return [String, nil]
      attr_reader :suggestion

      # @param location [Solargraph::Location]
      # @param message [String]
      # @param pin [Solargraph::Pin::Base, nil]
      # @param suggestion [String, nil]
      def initialize location, message, pin: nil, suggestion: nil
        @location = location
        @message = message
        @pin = pin
        @suggestion = suggestion
      end
    end
  end
end
