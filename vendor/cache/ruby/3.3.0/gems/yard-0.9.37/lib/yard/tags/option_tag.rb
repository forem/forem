# frozen_string_literal: true
module YARD
  module Tags
    class OptionTag < Tag
      attr_accessor :pair

      def initialize(tag_name, name, pair)
        super(tag_name, nil, nil, name)
        @pair = pair
      end
    end
  end
end
