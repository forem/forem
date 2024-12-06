# frozen_string_literal: true

module Solargraph
  class Source
    class Chain
      class BlockVariable < Link
        def resolve api_map, name_pin, locals
          [Pin::ProxyType.anonymous(ComplexType.try_parse('Proc'))]
        end
      end
    end
  end
end
