module ReverseMarkdown
  module Converters
    class Dd < Base
      def convert node, state = {}
        content = treat_children(node, state)
        ": #{content.strip}\n"
      end
    end
  end
end

ReverseMarkdown::Converters.register :dd, ReverseMarkdown::Converters::Dd.new
