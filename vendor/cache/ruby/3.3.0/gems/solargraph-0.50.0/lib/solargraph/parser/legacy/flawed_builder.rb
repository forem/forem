# frozen_string_literal: true

module Solargraph
  module Parser
    module Legacy
      # A custom builder for source parsers that ignores character encoding
      # issues in literal strings.
      #
      class FlawedBuilder < ::Parser::Builders::Default
        def string_value(token)
          value(token)
        end
      end
    end
  end
end
