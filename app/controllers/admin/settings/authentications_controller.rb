module Admin
  module Settings
    class AuthenticationsController < Admin::ApplicationController
      def create
        # TODO: service object similar to SiteConfig::Upsert
      end

      def settings_params
        params.require(:settings_authentication).permit(::Settings::Authentication.keys)
      end
    end
  end
end
