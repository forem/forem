require "fog/core"
require "nokogiri"
require File.expand_path("../xml/version", __FILE__)

module Fog
  autoload :ToHashDocument, File.expand_path("../to_hash_document", __FILE__)

  module XML
    autoload :SAXParserConnection, File.expand_path("../xml/sax_parser_connection", __FILE__)
    autoload :Connection, File.expand_path("../xml/connection", __FILE__)
    autoload :Response, File.expand_path("../xml/response", __FILE__)
  end

  module Parsers
    autoload :Base, File.expand_path("../parsers/base", __FILE__)
  end
end
