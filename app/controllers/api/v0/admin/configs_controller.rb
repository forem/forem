module Api
  module V0
    module Admin
      class ConfigsController < ApiController
        before_action :authenticate_super_admin!
        def show
          @site_config = SiteConfig.all
        end

        def create
          Admin::Configs::Upsert.call(params)
        end
      end
    end
  end
end
