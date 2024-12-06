# frozen_string_literal: true

module Solargraph
  class YardMap
    class Cache
      def initialize
        @path_pins = {}
      end

      def set_path_pins path, pins
        @path_pins[path] = pins
      end

      def get_path_pins path
        @path_pins[path]
      end
    end
  end
end
