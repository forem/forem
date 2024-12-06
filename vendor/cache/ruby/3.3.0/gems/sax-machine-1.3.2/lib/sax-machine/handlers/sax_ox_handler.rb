require 'sax-machine/handlers/sax_abstract_handler'
require 'ox'

module SAXMachine
  class SAXOxHandler < Ox::Sax
    include SAXAbstractHandler

    def initialize(*args)
      _initialize(*args)
      _reset_element
    end

    def sax_parse(xml_input)
      # Ox requires input to be streamable
      xml_input = StringIO.new(xml_input) if xml_input.is_a?(String)

      Ox.sax_parse(self, xml_input,
        symbolize: false,
        convert_special: true,
        skip: :skip_return,
      )
    end

    def attr(name, str)
      @attrs[name] = str
    end

    def attrs_done
      _start_element(@element, @attrs)
      _reset_element
    end

    def start_element(name)
      @element = name
    end

    def text(value)
      _characters(value) if value && !value.empty?
    end

    alias_method :cdata, :text

    def error(message, line, column)
      _error("#{message} on line #{line} column #{column}")
    end

    alias_method :end_element, :_end_element

    private

    def _reset_element
      @attrs = {}
      @element = ""
    end
  end
end
