module Admin
  module Settings
    class GeneralSettingsController < Admin::Settings::BaseController
      include SettingsParams

      def create
        result = ::Settings::Upsert.call(settings_params)
        if result.success?
          Audit::Logger.log(:internal, current_user, params.dup)
          bust_content_change_caches
          redirect_to admin_config_path, notice: "Successfully updated settings."
        else
          redirect_to admin_config_path, alert: "😭 #{result.errors.to_sentence}"
        end
      end

      private

      # NOTE: we need to override this since the controller name doesn't reflect
      # the model name
      def authorization_resource
        ::Settings::General
      end
    end
  end
end
