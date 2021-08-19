module Admin
  module Settings
    class RateLimitsController < Admin::Settings::BaseController
      private

      def authorization_resource
        ::Settings::RateLimit
      end
    end
  end
end
