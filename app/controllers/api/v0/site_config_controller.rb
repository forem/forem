module Api
  module V0
    class SiteConfigController < ApiController
      before_action :authenticate_super_admin!
      def show
        @site_config = SiteConfig.all
      end
    end
  end
end
