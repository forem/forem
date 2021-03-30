module Admin
  module Settings
    class AuthenticationsController < Admin::ApplicationController
      def create
        result = ::Settings::Authentications::Upsert.call(settings_params)

        if result.success?
          Audit::Logger.log(:internal, current_user, params.dup)
          redirect_to admin_config_path, notice: "Site configuration was successfully updated."
        else
          redirect_to admin_config_path, alert: "😭 #{result.errors.to_sentence}"
        end
      end

      def settings_params
        params
          .require(:settings_authentication)
          .permit(*::Settings::Authentication.keys, :providers_to_enable,
                  providers: [])
      end
    end
  end
end
