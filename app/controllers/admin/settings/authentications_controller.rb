module Admin
  module Settings
    class AuthenticationsController < Admin::Settings::BaseController
      private

      def upsert_config(settings)
        ::Settings::Authentication::Upsert.call(settings)
      end

      def settings_params
        params
          .require(:settings_authentication)
          .permit(*::Settings::Authentication.keys, :auth_providers_to_enable)
      end
    end
  end
end
