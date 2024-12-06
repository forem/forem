# frozen_string_literal: true

module Solargraph
  class Source
    class Chain
      class Constant < Link
        def initialize word
          @word = word
        end

        def resolve api_map, name_pin, locals
          return [Pin::ROOT_PIN] if word.empty?
          if word.start_with?('::')
            base = word[2..-1]
            gates = ['']
          else
            base = word
            gates = crawl_gates(name_pin)
          end
          parts = base.split('::')
          gates.each do |gate|
            type = deep_constant_type(gate, api_map)
            # Use deep inference to resolve root 
            parts[0..-2].each do |sym|
              pins = api_map.get_constants('', type.namespace).select{ |pin| pin.name == sym }
              type = first_pin_type(pins, api_map)
              break if type.undefined?
            end
            next if type.undefined?
            result = api_map.get_constants('', type.namespace).select { |pin| pin.name == parts.last }
            return result unless result.empty?
          end
          []
        end

        private

        def crawl_gates pin
          clos = pin
          until clos.nil?
            if clos.is_a?(Pin::Namespace)
              gates = clos.gates
              gates.push('') if gates.empty?
              return gates
            end
            clos = clos.closure
          end
          ['']
        end

        def first_pin_type(pins, api_map)
          type = ComplexType::UNDEFINED
          pins.each do |pin|
            type = pin.typify(api_map)
            break if type.defined?
            type = pin.probe(api_map)
            break if type.defined?
          end
          type
        end

        def deep_constant_type(gate, api_map)
          type = ComplexType::ROOT
          return type if gate == ''
          gate.split('::').each do |word|
            pins = api_map.get_constants('', type.namespace).select { |pin| pin.name == word }
            type = first_pin_type(pins, api_map)
            break if type.undefined?
          end
          type
        end
      end
    end
  end
end
