# frozen_string_literal: true

module Solargraph
  class TypeChecker
    # Data about a method parameter definition. This is the information from
    # the args list in the def call, not the `@param` tags.
    #
    class ParamDef
      # @return [String]
      attr_reader :name

      # @return [Symbol]
      attr_reader :type

      def initialize name, type
        @name = name
        @type = type
      end

      class << self
        # Get an array of ParamDefs from a method pin.
        #
        # @param pin [Solargraph::Pin::Method]
        # @return [Array<ParamDef>]
        def from pin
          result = []
          pin.parameters.each do |par|
            result.push ParamDef.new(par.name, par.decl)
          end
          result
        end
      end
    end
  end
end
