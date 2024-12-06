module Flipper
  module UI
    class Option
      attr_accessor :title, :description

      def initialize(title, description)
        @title = title
        @description = description
      end
    end
  end
end
