# frozen_string_literal: true

module Nokogiri
  module XML
    module SAX
      ###
      # Context for XML SAX parsers.  This class is usually not instantiated
      # by the user.  Instead, you should be looking at
      # Nokogiri::XML::SAX::Parser
      class ParserContext
        def self.new(thing, encoding = "UTF-8")
          if [:read, :close].all? { |x| thing.respond_to?(x) }
            io(thing, Parser::ENCODINGS[encoding])
          else
            memory(thing)
          end
        end
      end
    end
  end
end
