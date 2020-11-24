module Api
  module V0
    module Admin
      class ConfigsController < ApiController
        before_action :authorize_admin
        after_action :verify_authorized

        def show
          @site_configs = SiteConfig.all
        end

        private

        def authorization_resource
          self.class.name.demodulize.sub("Controller", "").singularize.constantize
        end

        def authorize_admin
          authorize(authorization_resource, :access?, policy_class: InternalPolicy)
        end
      end
    end
  end
end
