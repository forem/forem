class DeviseMailer < Devise::Mailer
  before_action :use_site_config_values

  def use_site_config_values
    Devise.mailer_sender =
      "#{Settings::General.community_name} <#{Settings::General.email_addresses[:default]}>"
    ActionMailer::Base.default_url_options[:host] = Settings::General.app_domain
  end
end
