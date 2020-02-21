module Search
  module Errors
    class Error < StandardError
    end

    module Transport
      class BadRequest < Error
      end

      class NotFound < Error
      end
    end
  end
end
