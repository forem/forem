module Github
  module Errors
    class Error < StandardError
    end

    class ClientError < Error
    end

    class ServerError < Error
    end

    class NotFound < ClientError
    end
  end
end
