module Api
  module V0
    module Admin
      class ConfigsController < ApiController
        before_action :authenticate_with_api_key_or_current_user!
        before_action :authorize_super_admin

        def show
          @site_configs = SiteConfig.all
        end
      end
    end
  end
end
