module Admin
  module Settings
    class GeneralSettingsController < Admin::Settings::BaseController
      after_action :bust_content_change_caches, only: %i[create]

      SPECIAL_PARAMS_TO_ADD = %w[
        credit_prices_in_cents
        meta_keywords
        logo
      ].freeze

      def create
        if settings_params[:logo].present?
          logo_uploader = upload_logo(settings_params[:logo])
          ::Settings::General.original_logo = logo_uploader.url
          ::Settings::General.resized_logo = logo_uploader.resized_logo.url
        end

        # The logo param is excluded because it needs to be handled by the logo uploader
        # Including it results in a NoMethodError - undefined method `strip'
        # for #<ActionDispatch::Http::UploadedFile:0x00007f9e6d85d7a8
        result = ::Settings::General::Upsert.call(settings_params.except(:logo))
        if result.success?
          Audit::Logger.log(:internal, current_user, params.dup)
          render json: { message: "Successfully updated settings." }, status: :ok
        else
          render json: { error: result.errors.to_sentence }, status: :unprocessable_entity
        end
      end

      def upload_logo(image)
        LogoUploader.new.tap do |uploader|
          uploader.store!(image)
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
