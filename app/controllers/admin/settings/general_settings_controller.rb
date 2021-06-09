module Admin
  module Settings
    class GeneralSettingsController < Admin::Settings::BaseController
      SPECIAL_PARAMS_TO_ADD = %w[
        credit_prices_in_cents
        email_addresses
        meta_keywords
      ].freeze

      def create
        result = ::Settings::General::Upsert.call(settings_params)
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

      def settings_params
        has_emails = params.dig(:settings_general, :email_addresses).present?
        params[:settings_general][:email_addresses][:default] = ApplicationConfig["DEFAULT_EMAIL"] if has_emails

        params.require(:settings_general)&.permit(
          settings_keys.map(&:to_sym),
          social_media_handles: ::Settings::General.social_media_handles.keys,
          email_addresses: ::Settings::General.email_addresses.keys,
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
