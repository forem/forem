# frozen_string_literal: true

module Solargraph
  module Pin
    class Closure < Base
      # @return [::Symbol] :class or :instance
      attr_reader :scope

      def initialize scope: :class, **splat
        super(**splat)
        @scope = scope
      end

      def context
        @context ||= begin
          result = super
          if scope == :instance
            Solargraph::ComplexType.parse(result.namespace)
          else
            result
          end
        end
      end

      def binder
        @binder || context
      end

      # @return [Array<String>]
      def gates
        # @todo This check might not be necessary. There should always be a
        #   root pin
        closure ? closure.gates : ['']
      end
    end
  end
end
