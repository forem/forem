# frozen_string_literal: true

module Solargraph
  class Source
    class Chain
      class InstanceVariable < Link
        def resolve api_map, name_pin, locals
          api_map.get_instance_variable_pins(name_pin.binder.namespace, name_pin.binder.scope).select{|p| p.name == word}
        end
      end
    end
  end
end
