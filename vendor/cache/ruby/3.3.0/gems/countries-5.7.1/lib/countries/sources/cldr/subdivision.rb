# frozen_string_literal: true

module Sources
  module CLDR
    # Auxiliary Subdivision class to support loading Unicode CLDR data to update local files
    class Subdivision
      attr_reader :xml, :language_code

      def initialize(language_code:, xml:)
        @language_code = language_code
        @xml = xml
      end

      def text
        xml.text
      end

      def country_code
        type[0..1].upcase
      end

      def code
        type[2..].upcase
      end

      def type
        xml.attributes['type'].value.delete('-')
      end

      def to_h
        data = {}
        data['translations'] ||= {}
        data['translations'][language_code] = text
        data
      end
    end
  end
end
