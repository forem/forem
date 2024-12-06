require "nokogiri"

module Fog
  module Parsers
    class Base < Nokogiri::XML::SAX::Document
      attr_reader :response

      def initialize
        reset
      end

      def attr_value(name, attrs)
        (entry = attrs.find {|a| a.localname == name }) && entry.value
      end

      def reset
        @response = {}
      end

      def characters(string)
        @value ||= ''
        @value << string
      end

      # ###############################################################################
      # This is a workaround. Original implementation from Nokogiri is overwritten with
      # one that does not join namespace prefix with local name.
      def start_element_namespace name, attrs = [], prefix = nil, uri = nil, ns = []
        start_element name, attrs
      end

      def end_element_namespace name, prefix = nil, uri = nil
        end_element name
      end

      # ###############################################################################

      def start_element(name, attrs = [])
        @value = nil
      end

      def value
        @value && @value.dup
      end
    end
  end
end

