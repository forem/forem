# frozen_string_literal: true

module Nokogiri
  module XML
    class << self
      ###
      # Create a new Nokogiri::XML::Schema object using a +string_or_io+
      # object.
      def Schema(string_or_io, options = ParseOptions::DEFAULT_SCHEMA)
        Schema.new(string_or_io, options)
      end
    end

    ###
    # Nokogiri::XML::Schema is used for validating XML against a schema
    # (usually from an xsd file).
    #
    # == Synopsis
    #
    # Validate an XML document against a Schema.  Loop over the errors that
    # are returned and print them out:
    #
    #   xsd = Nokogiri::XML::Schema(File.read(PO_SCHEMA_FILE))
    #   doc = Nokogiri::XML(File.read(PO_XML_FILE))
    #
    #   xsd.validate(doc).each do |error|
    #     puts error.message
    #   end
    #
    # The list of errors are Nokogiri::XML::SyntaxError objects.
    #
    # NOTE: As of v1.11.0, Schema treats inputs as UNTRUSTED by default, and so external entities
    # are not resolved from the network (`http://` or `ftp://`). Previously, parsing treated
    # documents as "trusted" by default which was counter to Nokogiri's "untrusted by default"
    # security policy. If a document is trusted, then the caller may turn off the NONET option via
    # the ParseOptions to re-enable external entity resolution over a network connection.
    class Schema
      # Errors while parsing the schema file
      attr_accessor :errors
      # The Nokogiri::XML::ParseOptions used to parse the schema
      attr_accessor :parse_options

      ###
      # Create a new Nokogiri::XML::Schema object using a +string_or_io+
      # object.
      def self.new(string_or_io, options = ParseOptions::DEFAULT_SCHEMA)
        from_document(Nokogiri::XML(string_or_io), options)
      end

      ###
      # Validate +thing+ against this schema.  +thing+ can be a
      # Nokogiri::XML::Document object, or a filename.  An Array of
      # Nokogiri::XML::SyntaxError objects found while validating the
      # +thing+ is returned.
      def validate(thing)
        if thing.is_a?(Nokogiri::XML::Document)
          validate_document(thing)
        elsif File.file?(thing)
          validate_file(thing)
        else
          raise ArgumentError, "Must provide Nokogiri::Xml::Document or the name of an existing file"
        end
      end

      ###
      # Returns true if +thing+ is a valid Nokogiri::XML::Document or
      # file.
      def valid?(thing)
        validate(thing).empty?
      end
    end
  end
end
