# frozen_string_literal: true

module Solargraph
  class Source
    class Chain
      class Literal < Link
        def word
          @word ||= "<#{@type}>"
        end

        # @param type [String]
        def initialize type
          @type = type
          @complex_type = ComplexType.try_parse(type)
        end

        def resolve api_map, name_pin, locals
          [Pin::ProxyType.anonymous(@complex_type)]
        end
      end
    end
  end
end
