module TwitterClient
  module Errors
    class Error < StandardError
    end

    class ClientError < Error
    end

    class ServerError < Error
    end

    class NotFound < ClientError
    end

    class BadRequest < ClientError
    end
  end
end
