# frozen_string_literal: true

module Nokogiri
  module XML
    ###
    # Nokogiri::XML::Reader parses an XML document similar to the way a cursor would move. The
    # Reader is given an XML document, and yields nodes to an each block.
    #
    # The Reader parser might be good for when you need the speed and low memory usage of the SAX
    # parser, but do not want to write a Document handler.
    #
    # Here is an example of usage:
    #
    #     reader = Nokogiri::XML::Reader(<<-eoxml)
    #       <x xmlns:tenderlove='http://tenderlovemaking.com/'>
    #         <tenderlove:foo awesome='true'>snuggles!</tenderlove:foo>
    #       </x>
    #     eoxml
    #
    #     reader.each do |node|
    #
    #       # node is an instance of Nokogiri::XML::Reader
    #       puts node.name
    #
    #     end
    #
    # ⚠ Nokogiri::XML::Reader#each can only be called once! Once the cursor moves through the entire
    # document, you must parse the document again. It may be better to capture all information you
    # need during a single iteration.
    #
    # ⚠ libxml2 does not support error recovery in the Reader parser. The `RECOVER` ParseOption is
    # ignored. If a syntax error is encountered during parsing, an exception will be raised.
    class Reader
      include Enumerable

      TYPE_NONE = 0
      # Element node type
      TYPE_ELEMENT = 1
      # Attribute node type
      TYPE_ATTRIBUTE = 2
      # Text node type
      TYPE_TEXT = 3
      # CDATA node type
      TYPE_CDATA = 4
      # Entity Reference node type
      TYPE_ENTITY_REFERENCE = 5
      # Entity node type
      TYPE_ENTITY = 6
      # PI node type
      TYPE_PROCESSING_INSTRUCTION = 7
      # Comment node type
      TYPE_COMMENT = 8
      # Document node type
      TYPE_DOCUMENT = 9
      # Document Type node type
      TYPE_DOCUMENT_TYPE = 10
      # Document Fragment node type
      TYPE_DOCUMENT_FRAGMENT = 11
      # Notation node type
      TYPE_NOTATION = 12
      # Whitespace node type
      TYPE_WHITESPACE = 13
      # Significant Whitespace node type
      TYPE_SIGNIFICANT_WHITESPACE = 14
      # Element end node type
      TYPE_END_ELEMENT = 15
      # Entity end node type
      TYPE_END_ENTITY = 16
      # XML Declaration node type
      TYPE_XML_DECLARATION = 17

      # A list of errors encountered while parsing
      attr_accessor :errors

      # The XML source
      attr_reader :source

      alias_method :self_closing?, :empty_element?

      def initialize(source, url = nil, encoding = nil) # :nodoc:
        @source   = source
        @errors   = []
        @encoding = encoding
      end
      private :initialize

      # Get the attributes and namespaces of the current node as a Hash.
      #
      # This is the union of Reader#attribute_hash and Reader#namespaces
      #
      # [Returns]
      #   (Hash<String, String>) Attribute names and values, and namespace prefixes and hrefs.
      def attributes
        attribute_hash.merge(namespaces)
      end

      ###
      # Move the cursor through the document yielding the cursor to the block
      def each
        while (cursor = read)
          yield cursor
        end
      end
    end
  end
end
