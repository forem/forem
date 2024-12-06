# frozen_string_literal: true
module YARD
  module Tags
    class DefaultTag < Tag
      attr_reader :defaults

      def initialize(tag_name, text, types = nil, name = nil, defaults = nil)
        super(tag_name, text, types, name)
        @defaults = defaults
      end
    end
  end
end
