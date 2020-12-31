module Api
  module V0
    module Admin
      class ConfigsController < ApiController
        include SiteConfigParams

        before_action :authenticate_with_api_key_or_current_user!
        before_action :authorize_super_admin
        skip_before_action :verify_authenticity_token, only: %i[update]

        def show
          @site_configs = SiteConfig.all
        end

        def update
          result = SiteConfigs::Upsert.call(site_config_params)
          if result.success?
            @site_configs = SiteConfig.all
            Audit::Logger.log(:internal, @user, params.dup)
            bust_content_change_caches
            render "show"
          else
            render json: { error: result.errors.to_sentence, status: 422 }, status: :unprocessable_entity
          end
        end
      end
    end
  end
end
