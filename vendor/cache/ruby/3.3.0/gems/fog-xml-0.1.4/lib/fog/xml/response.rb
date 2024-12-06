module Fog
  module XML
    class Response
      def initialize(parser)
        @parser = parser
        @data_stream = Nokogiri::XML::SAX::PushParser.new(parser)
        @response_string = ""
      end

      def call(chunk, _remaining, _total)
        @response_string << chunk if ENV["DEBUG_RESPONSE"]
        @data_stream << chunk
      end

      def rewind
        @parser.reset
        @response_string = ""
      end

      def finish
        Fog::Logger.debug "\n#{@response_string}" if ENV["DEBUG_RESPONSE"]
        @data_stream.finish
      end
    end
  end
end
