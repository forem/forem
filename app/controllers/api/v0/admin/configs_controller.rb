module Api
  module V0
    module Admin
      class ConfigsController < ApiController
        include SiteConfigParams

        before_action :authenticate_with_api_key_or_current_user!
        before_action :authorize_super_admin
        after_action :bust_content_change_caches, only: [:create]

        after_action only: [:update] do
          Audit::Logger.log(:internal, @user, params.dup)
        end

        def show
          @site_configs = SiteConfig.all
        end

        def create
          result = SiteConfigs::Upsert.call(site_config_params)
          if result[:result] == "errors"
            render json: { error: result[:errors], status: 422 }, status: :unprocessable_entity
            return
          end
          @site_configs = SiteConfig.all
          render "show"
        end
      end
    end
  end
end
