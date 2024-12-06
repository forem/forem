module MetaInspector
  module Parsers
    ##
    # Base class from where the specialized parsers inherit from.
    #
    # On initialization a main parser is expected, so the specialized
    # parsers can request the parsed document to the main parser, and
    # then perform the searches on it.
    #
    # The main parser also serves as a message hub between the specialized
    # parsers. For example, the ImagesParser needs to know the base_url
    # in order to absolutify image URLs, so it delegates it to the main parser
    # which, in turn, delegates it to the LinksParser.
    #
    class Base
      def initialize(main_parser)
        @main_parser = main_parser
      end

      extend Forwardable

      private

      # Cleans up nokogiri search results
      def cleanup(results)
        results.map { |r| r.value.strip }.reject(&:empty?).uniq
      end
    end
  end
end
