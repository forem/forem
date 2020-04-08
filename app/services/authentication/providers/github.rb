module Authentication
  module Providers
    # GitHub authentication provider, uses omniauth-github as backend
    module Github
      NAME = "github".freeze

      # Returns identity data from the OmniAuth strategy payload
      def self.identity_data(auth_payload)
        return {} unless auth_payload.provider == NAME

        { github_created_at: auth_payload.extra.raw_info.created_at }
      end

      # Returns data to update the user with
      def self.user_data(auth_payload)
        return {} unless auth_payload.provider == NAME

        { github_username: auth_payload.info.nickname }
      end
    end
  end
end
