# frozen_string_literal: true

module Solargraph
  module Pin
    # Use this class to track method aliases for later remapping. Common
    # examples that defer mapping are aliases for superclass methods or
    # methods from included modules.
    #
    class MethodAlias < Method
      # @return [::Symbol]
      attr_reader :scope

      # @return [String]
      attr_reader :original

      def initialize scope: :instance, original: nil, **splat
        super(**splat)
        @scope = scope
        @original = original
      end

      def visibility
        :public
      end

      def path
        @path ||= namespace + (scope == :instance ? '#' : '.') + name
      end
    end
  end
end
