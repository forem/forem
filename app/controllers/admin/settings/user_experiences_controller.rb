module Admin
  module Settings
    class UserExperiencesController < Admin::ApplicationController
      def create
        errors = upsert_config(settings_params)

        if errors.none?
          Audit::Logger.log(:internal, current_user, params.dup)
          redirect_to admin_config_path, notice: "Site configuration was successfully updated."
        else
          redirect_to admin_config_path, alert: "😭 #{errors.to_sentence}"
        end
      end

      def settings_params
        params
          .require(:settings_user_experience)
          .permit(*::Settings::UserExperience.keys)
      end

      def upsert_config(configs)
        errors = []
        configs.each do |key, value|
          ::Settings::UserExperience.public_send("#{key}=", value) if value.present?
        rescue ActiveRecord::RecordInvalid => e
          errors << e.message
          next
        end

        errors
      end
    end
  end
end
