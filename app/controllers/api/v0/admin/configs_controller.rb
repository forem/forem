module Api
  module V0
    module Admin
      class ConfigsController < ApiController
        before_action :authenticate_with_api_key_or_current_user!
        before_action :authorize_super_admin
        after_action :bust_content_change_caches, only: [:create]

        def show
          @site_configs = SiteConfig.all
        end

        def create
          result = SiteConfigs::Upsert.call(config_params)
          if result[:result] == "errors"
            render json: { error: result[:errors], status: 422 }, status: :unprocessable_entity
            return
          end
          @site_configs = SiteConfig.all
          render "show", status: :ok
        end

        def config_params
          special_params_to_remove = %w[authentication_providers email_addresses meta_keywords credit_prices_in_cents]
          special_params_to_add = %w[auth_providers_to_enable]
          has_emails = params.dig(:site_config, :email_addresses).present?
          params[:site_config][:email_addresses][:default] = ApplicationConfig["DEFAULT_EMAIL"] if has_emails
          params&.require(:site_config)&.permit(
            (SiteConfig.keys - special_params_to_remove + special_params_to_add).map(&:to_sym),
            authentication_providers: [],
            social_media_handles: SiteConfig.social_media_handles.keys,
            email_addresses: SiteConfig.email_addresses.keys,
            meta_keywords: SiteConfig.meta_keywords.keys,
            credit_prices_in_cents: SiteConfig.credit_prices_in_cents.keys,
          )
        end
      end
    end
  end
end
