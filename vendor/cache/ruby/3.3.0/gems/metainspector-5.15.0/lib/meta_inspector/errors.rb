require 'nesty'

module MetaInspector
  class Error < StandardError
    include Nesty::NestedError
  end

  class TimeoutError < Error; end

  class RequestError < Error; end

  class ParserError < Error; end

  class NonHtmlError < ParserError; end
end
