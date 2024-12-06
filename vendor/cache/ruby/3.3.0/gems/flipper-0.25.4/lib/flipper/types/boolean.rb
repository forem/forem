require 'flipper/typecast'

module Flipper
  module Types
    class Boolean < Type
      def initialize(value = nil)
        @value = value.nil? ? true : Typecast.to_boolean(value)
      end
    end
  end
end
