# Changing the value for "domain" in each context instead of using the one set on boot.
# This allows changing domain settings without restarting app.
module Devise
  module Controllers
    module Rememberable
      # We need to use Settings::General.app_domain instead of default Rails config on boot
      def remember_cookie_values(resource)
        options = { httponly: true }
        options.merge!(forget_cookie_values(resource))
        options.merge!(
          value: resource.class.serialize_into_cookie(resource),
          expires: resource.remember_expires_at,
          domain: ".#{Settings::General.app_domain}",
        )
      end

      def self.cookie_values
        # Default: Rails.configuration.session_options.slice(:path, :domain, :secure)
        # We need to use Settings::General.app_domain instead of default Rails config on boot
        { domain: ".#{Settings::General.app_domain}", secure: ApplicationConfig["FORCE_SSL_IN_RAILS"] == "true" }
      end
    end
  end
end
