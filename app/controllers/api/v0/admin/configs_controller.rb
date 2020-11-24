module Api
  module V0
    module Admin
      class ConfigsController < ApiController
        before_action :authenticate!
        before_action :authorize_super_admin

        def show
          @site_configs = SiteConfig.all
        end
      end
    end
  end
end
