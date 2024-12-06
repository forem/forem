module Solargraph
  module Parser
    class Snippet
      attr_reader :range
      attr_reader :text

      def initialize range, text
        @range = range
        @text = text
      end
    end
  end
end
