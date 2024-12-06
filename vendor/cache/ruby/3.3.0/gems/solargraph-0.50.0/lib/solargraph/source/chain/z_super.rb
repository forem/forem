# frozen_string_literal: true

module Solargraph
  class Source
    class Chain
      class ZSuper < Call
        # @return [String]
        attr_reader :word

        # @return [Array<Chain>]
        attr_reader :arguments

        # @param word [String]
        # @param arguments [Array<Chain>]
        # @param with_block [Boolean] True if the chain is inside a block
        # @param head [Boolean] True if the call is the start of its chain
        def initialize word, with_block = false
          super(word, [], with_block)
        end

        # @param api_map [ApiMap]
        # @param name_pin [Pin::Base]
        # @param locals [Array<Pin::Base>]
        def resolve api_map, name_pin, locals
          return super_pins(api_map, name_pin)
        end
      end
    end
  end
end
