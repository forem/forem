module Api
  module V0
    module Admin
      class ConfigsController < ApiController
        include SettingsParams

        before_action :authenticate_with_api_key_or_current_user!
        before_action :authorize_super_admin
        skip_before_action :verify_authenticity_token, only: %i[update]

        def show
          @settings =
            Settings::Authentication.all +
            Settings::Campaign.all +
            Settings::Community.all +
            Settings::General.all +
            Settings::Mascot.all +
            Settings::RateLimit.all +
            Settings::UserExperience.all
        end

        def update
          # NOTE: citizen428 - this is not going to scale but I want to wait
          # until we extract at least one more settings model before deciding
          # how to change this.
          settings_result = ::Settings::Upsert.call(settings_params)
          auth_settings_result = ::Authentication::SettingsUpsert.call(auth_settings_params)

          if settings_result.success? && auth_settings_result.success?
            @settings = Settings::General.all + Settings::Authentication.all
            Audit::Logger.log(:internal, @user, params.dup)
            bust_content_change_caches
            render "show"
          else
            errors = settings_result.errors + auth_settings_result.errors
            render json: { error: errors.to_sentence, status: 422 }, status: :unprocessable_entity
          end
        end

        private

        def auth_settings_params
          params
            .require(:site_config)
            .permit(*::Settings::Authentication.keys, :providers_to_enable)
        end
      end
    end
  end
end
