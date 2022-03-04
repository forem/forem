class DeviseMailer < Devise::Mailer
  default reply_to: proc { ForemInstance.reply_to_email_address }

  include Deliverable

  before_action :use_settings_general_values

  def use_settings_general_values
    Devise.mailer_sender =
      "#{Settings::Community.community_name} <#{ForemInstance.from_email_address}>"
    ActionMailer::Base.default_url_options[:host] = Settings::General.app_domain
  end
end
