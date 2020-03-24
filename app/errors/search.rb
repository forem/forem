module Search
  module Errors
    class Error < StandardError
    end

    class SubclassResponsibility < Error
    end

    module Transport
      class TransportError < Error
      end

      class BadRequest < Error
      end

      class NotFound < Error
      end
    end
  end
end
