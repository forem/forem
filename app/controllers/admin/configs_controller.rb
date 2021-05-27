module Admin
  class ConfigsController < Admin::SettingsController
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
  end
end
