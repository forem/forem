module Admin
  module Settings
    class GeneralSettingsController < Admin::Settings::BaseController
      after_action :bust_content_change_caches, only: %i[create]

      SPECIAL_PARAMS_TO_ADD = %w[
        credit_prices_in_cents
        meta_keywords
      ].freeze

      def create
        result = ::Settings::General::Upsert.call(settings_params)
        if result.success?
          Audit::Logger.log(:internal, current_user, params.dup)
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

      def settings_params
        params.require(:settings_general)&.permit(
          settings_keys.map(&:to_sym),
          social_media_handles: ::Settings::General.social_media_handles.keys,
          meta_keywords: ::Settings::General.meta_keywords.keys,
          credit_prices_in_cents: ::Settings::General.credit_prices_in_cents.keys,
        )
      end

      def settings_keys
        ::Settings::General.keys + SPECIAL_PARAMS_TO_ADD
      end
    end
  end
end
