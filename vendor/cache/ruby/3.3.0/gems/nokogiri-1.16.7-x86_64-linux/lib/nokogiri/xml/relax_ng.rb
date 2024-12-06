# frozen_string_literal: true

module Nokogiri
  module XML
    class << self
      ###
      # Create a new Nokogiri::XML::RelaxNG document from +string_or_io+.
      # See Nokogiri::XML::RelaxNG for an example.
      def RelaxNG(string_or_io, options = ParseOptions::DEFAULT_SCHEMA)
        RelaxNG.new(string_or_io, options)
      end
    end

    ###
    # Nokogiri::XML::RelaxNG is used for validating XML against a
    # RelaxNG schema.
    #
    # == Synopsis
    #
    # Validate an XML document against a RelaxNG schema.  Loop over the errors
    # that are returned and print them out:
    #
    #   schema  = Nokogiri::XML::RelaxNG(File.open(ADDRESS_SCHEMA_FILE))
    #   doc     = Nokogiri::XML(File.open(ADDRESS_XML_FILE))
    #
    #   schema.validate(doc).each do |error|
    #     puts error.message
    #   end
    #
    # The list of errors are Nokogiri::XML::SyntaxError objects.
    #
    # NOTE: RelaxNG input is always treated as TRUSTED documents, meaning that they will cause the
    # underlying parsing libraries to access network resources. This is counter to Nokogiri's
    # "untrusted by default" security policy, but is a limitation of the underlying libraries.
    class RelaxNG < Nokogiri::XML::Schema
    end
  end
end
