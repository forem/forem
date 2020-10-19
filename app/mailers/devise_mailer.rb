class DeviseMailer < Devise::Mailer
  helper Rails.application.routes.url_helpers
  helper ApplicationHelper
  helper AuthenticationHelper

  before_action :use_custom_host

  default(
    from: -> { email_from("Community") },
  )

  def email_from(topic)
    "#{SiteConfig.community_name} #{topic} <#{SiteConfig.email_addresses[:default]}>"
  end

  def use_custom_host
    ActionMailer::Base.default_url_options[:host] = SiteConfig.app_domain
  end
end
