module LiquidTags
  module Errors
    class Error < StandardError
    end

    class InvalidParsedContext < Error
    end
  end
end
