# Module to override callback_url for MLH strategy
# This ensures redirect_uri never includes query parameters, which MLH requires
module OmniAuth
  module Strategies
    module MlhCallbackUrlOverride
      # Override callback_url to ensure it never includes query parameters
      # MLH requires the redirect_uri to match exactly what's registered
      def callback_url
        # Return the base callback URL without any query parameters
        callback_path = "/users/auth/mlh/callback"
        "#{full_host}#{script_name}#{callback_path}"
      end
    end
  end
end
