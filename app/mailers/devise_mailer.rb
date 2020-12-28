class DeviseMailer < Devise::Mailer
  before_action :use_site_config_values

  def use_site_config_values
    Devise.mailer_sender =
      "#{SiteConfig.community_name} <#{SiteConfig.email_addresses[:default]}>"
    ActionMailer::Base.default_url_options[:host] = SiteConfig.app_domain
  end
end
