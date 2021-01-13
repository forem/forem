module UserDestroyToken
  module Errors
    class Error < StandardError
    end

    # user-destroy-tokens are sent to a user's email upon account deletion request.
    # An error is raised if the token is invalid, which happens if the token has expired.
    class InvalidToken < Error
      # rubocop:disable Layout/LineLength
      def initialize(msg = "Your token has expired, please request a new one. Tokens only last for 12 hours after account deletion is initiated.")
        super(msg)
      end
      # rubocop:enable Layout/LineLength
    end
  end
end
