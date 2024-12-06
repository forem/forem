module ReverseMarkdown
  module Converters
    class Dl < Base
      def convert node, state = {}
        content = treat_children(node, state).strip
        "\n\n#{content}\n"
      end
    end
  end
end

ReverseMarkdown::Converters.register :dl, ReverseMarkdown::Converters::Dl.new
