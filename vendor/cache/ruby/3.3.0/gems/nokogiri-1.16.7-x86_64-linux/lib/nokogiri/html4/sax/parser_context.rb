# frozen_string_literal: true

module Nokogiri
  module HTML4
    module SAX
      ###
      # Context for HTML SAX parsers. This class is usually not instantiated by the user. Instead,
      # you should be looking at Nokogiri::HTML4::SAX::Parser
      class ParserContext < Nokogiri::XML::SAX::ParserContext
        def self.new(thing, encoding = "UTF-8")
          if [:read, :close].all? { |x| thing.respond_to?(x) }
            super
          else
            memory(thing, encoding)
          end
        end
      end
    end
  end
end
