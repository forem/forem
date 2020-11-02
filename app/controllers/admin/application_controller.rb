module Admin
  class ApplicationController < ApplicationController
    before_action :authorize_admin
    after_action :verify_authorized

    private

    def authorization_resource
      self.class.name.demodulize.sub("Controller", "").singularize.constantize
    end

    def authorize_admin
      authorize(authorization_resource, :access?, policy_class: InternalPolicy)
    end

    def bust_content_change_caches
      CacheBuster.bust("/tags/onboarding") # Needs to change when suggested_tags is edited.
      CacheBuster.bust("/shell_top") # Cached at edge, sent to service worker.
      CacheBuster.bust("/shell_bottom") # Cached at edge, sent to service worker.
      CacheBuster.bust("/onboarding") # Page is cached at edge.
      CacheBuster.bust("/") # Page is cached at edge.
      SiteConfig.admin_action_taken_at = Time.current # Used as cache key
    end
  end
end
