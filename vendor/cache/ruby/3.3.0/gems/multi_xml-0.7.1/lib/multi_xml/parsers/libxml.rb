require "libxml" unless defined?(LibXML)
require "multi_xml/parsers/libxml2_parser"

module MultiXml
  module Parsers
    module Libxml # :nodoc:
      include Libxml2Parser
      extend self

      def parse_error
        ::LibXML::XML::Error
      end

      def parse(xml)
        node_to_hash(LibXML::XML::Parser.io(xml).parse.root)
      end

      private

      def each_child(node, &)
        node.each_child(&)
      end

      def each_attr(node, &)
        node.each_attr(&)
      end

      def node_name(node)
        node.name
      end
    end
  end
end
