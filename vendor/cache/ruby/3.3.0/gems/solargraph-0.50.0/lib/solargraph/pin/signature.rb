module Solargraph
  module Pin
    class Signature
      # @return [Array<Parameter>]
      attr_reader :parameters

      # @return [ComplexType]
      attr_reader :return_type

      attr_reader :block

      def initialize parameters, return_type, block = nil
        @parameters = parameters
        @return_type = return_type
        @block = block
      end

      def block?
        !!@block
      end
    end
  end
end
