module Admin
  module Settings
    class MandatorySettingsController < Admin::ApplicationController
      def create
        errors = upsert_config(settings_params)

        if errors.none?
          Audit::Logger.log(:internal, current_user, params.dup)
          redirect_to admin_config_path, notice: "Successfully updated settings."
        else
          redirect_to admin_config_path, alert: "😭 #{errors.to_sentence}"
        end
      end

      def upsert_config(configs)
        errors = []
        configs.each do |key, value|
          settings_model = ::Settings::Mandatory::MAPPINGS[key.to_sym]
          if value.is_a?(Array)
            settings_model.public_send("#{key}=", value.reject(&:blank?)) if value.present?
          else
            settings_model.public_send("#{key}=", value.strip) unless value.nil?
          end
        rescue ActiveRecord::RecordInvalid => e
          errors << e.message
          next
        end

        errors
      end

      private

      # NOTE: we need to override this since the controller name doesn't reflect
      # the model name
      def authorization_resource
        ::Settings::Mandatory
      end

      def settings_params
        params.permit(::Settings::Mandatory.keys)
      end
    end
  end
end
