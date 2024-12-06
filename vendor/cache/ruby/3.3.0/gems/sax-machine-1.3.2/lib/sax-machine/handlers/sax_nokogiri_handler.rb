require 'sax-machine/handlers/sax_abstract_handler'
require 'nokogiri'

module SAXMachine
  class SAXNokogiriHandler < Nokogiri::XML::SAX::Document
    include SAXAbstractHandler

    def sax_parse(xml_input)
      parser = Nokogiri::XML::SAX::Parser.new(self)
      parser.parse(xml_input) do |ctx|
        ctx.replace_entities = true
      end
    end

    alias_method :initialize, :_initialize
    alias_method :characters, :_characters
    alias_method :cdata_block, :_characters
    alias_method :start_element, :_start_element
    alias_method :end_element, :_end_element
    alias_method :error, :_error
    alias_method :warning, :_warning
  end
end
