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
