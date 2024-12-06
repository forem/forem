module ReverseMarkdown
  module Converters
    class Dt < Base
      def convert node, state = {}
        content = treat_children(node, state)
        "\n#{content.strip}\n"
      end
    end
  end
end

ReverseMarkdown::Converters.register :dt, ReverseMarkdown::Converters::Dt.new
