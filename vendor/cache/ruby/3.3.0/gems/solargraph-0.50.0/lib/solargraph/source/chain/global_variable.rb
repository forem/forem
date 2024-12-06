# frozen_string_literal: true

module Solargraph
  class Source
    class Chain
      class GlobalVariable < Link
        def resolve api_map, name_pin, locals
          api_map.get_global_variable_pins.select{|p| p.name == word}
        end
      end
    end
  end
end
