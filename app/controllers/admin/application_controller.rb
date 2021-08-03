module Admin
  class ApplicationController < ApplicationController
    before_action :authorize_admin
    before_action :assign_help_url
    after_action :verify_authorized

    HELP_URLS = {
      badges: "https://admin.forem.com/docs/admin/badges",
      badge_achievements: "https://admin.forem.com/docs/admin/badges",
      configs: "https://admin.forem.com/docs/admin/config/README",
      navigation_links: "https://admin.forem.com/docs/admin/navigation-links",
      pages: "https://admin.forem.com/docs/admin/pages",
      podcasts: "https://admin.forem.com/docs/admin/podcasts",
      reports: "https://admin.forem.com/docs/admin/reports",
      users: "https://admin.forem.com/docs/admin/users/README",
      html_variants: "https://admin.forem.com/docs/admin/html-variants",
      display_ads: "https://admin.forem.com/docs/admin/display-ads",
      chat_channels: "https://admin.forem.com/docs/admin/chat-channels",
      tags: "https://admin.forem.com/docs/admin/tags"
    }.freeze

    private

    def authorization_resource
      self.class.name.sub("Admin::", "").sub("Controller", "").singularize.constantize
    end

    def authorize_admin
      authorize(authorization_resource, :access?, policy_class: InternalPolicy)
    end

    def assign_help_url
      @help_url = HELP_URLS[controller_name.to_sym]
    end
  end
end
