module Admin
  class ApplicationController < ApplicationController
    before_action :authorize_admin
    before_action :assign_help_url
    after_action :verify_authorized

    HELP_URLS = {
      badges: "https://forem.gitbook.io/forem-admin-guide/admin/badges",
      badge_achievements: "https://forem.gitbook.io/forem-admin-guide/admin/badges",
      configs: "https://forem.gitbook.io/forem-admin-guide/admin/config",
      navigation_links: "https://forem.gitbook.io/forem-admin-guide/admin/navigation-links",
      pages: "https://forem.gitbook.io/forem-admin-guide/admin/pages",
      podcasts: "https://forem.gitbook.io/forem-admin-guide/admin/podcasts",
      reports: "https://forem.gitbook.io/forem-admin-guide/admin/reports",
      users: "https://forem.gitbook.io/forem-admin-guide/admin/users",
      html_variants: "https://forem.gitbook.io/forem-admin-guide/admin/html-variants",
      display_ads: "https://forem.gitbook.io/forem-admin-guide/admin/display-ads",
      chat_channels: "https://forem.gitbook.io/forem-admin-guide/admin/chat-channels",
      tags: "https://forem.gitbook.io/forem-admin-guide/admin/tags"
    }.freeze

    private

    def authorization_resource
      self.class.name.sub("Admin::", "").sub("Controller", "").singularize.constantize
    end

    def authorize_admin
      authorize(authorization_resource, :access?, policy_class: InternalPolicy)
    end

    def bust_content_change_caches
      CacheBuster.bust("/tags/onboarding") # Needs to change when suggested_tags is edited.
      CacheBuster.bust("/shell_top") # Cached at edge, sent to service worker.
      CacheBuster.bust("/shell_bottom") # Cached at edge, sent to service worker.
      CacheBuster.bust("/async_info/shell_version") # Checks if current users should be busted.
      CacheBuster.bust("/onboarding") # Page is cached at edge.
      CacheBuster.bust("/") # Page is cached at edge.
      SiteConfig.admin_action_taken_at = Time.current # Used as cache key
    end

    def assign_help_url
      @help_url = HELP_URLS[controller_name.to_sym]
    end
  end
end
