module Fog
  module XML
    class Connection < SAXParserConnection
      def request(params, &_block)
        parser = params.delete(:parser)
        if parser
          super(parser, params)
        else
          original_request(params)
        end
      end
    end
  end
end
