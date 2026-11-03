module Github
  module Errors
    class Error < StandardError
      # HTTP response status from the originating Octokit error, when known, so
      # callers can classify failures (e.g. 429 rate limiting) by status rather
      # than by matching message text.
      attr_reader :response_status

      # Accept the message positionally or via the `message:` keyword (existing
      # callers use the keyword form), and optionally carry the HTTP status.
      def initialize(message = nil, response_status: nil, **kwargs)
        message ||= kwargs[:message]
        super(message)
        @response_status = response_status
      end
    end

    class ClientError < Error
    end

    class ServerError < Error
    end

    class NotFound < ClientError
    end

    class Unauthorized < ClientError
    end

    class InvalidRepository < ArgumentError
    end

    class AccountSuspended < ClientError
    end

    class RepositoryUnavailable < ClientError
    end

    # Octokit raises these for primary rate-limit (HTTP 429) and abuse/secondary
    # rate-limit (HTTP 403) responses. handle_error maps them by class name so
    # callers can classify rate limiting by type rather than by message text.
    class TooManyRequests < ClientError
    end

    class TooManyLoginAttempts < ClientError
    end
  end
end
