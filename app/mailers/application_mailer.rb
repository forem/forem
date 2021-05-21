class ApplicationMailer < ActionMailer::Base
  layout "mailer"
  # the order of importing the helpers here is important
  # we want the application helpers to override the Rails route helpers should there be a name conflict
  # an example is the user_url
  helper Rails.application.routes.url_helpers
  helper ApplicationHelper
  helper AuthenticationHelper

  before_action :use_custom_host

  default(
    from: -> { email_from },
    template_path: ->(mailer) { "mailers/#{mailer.class.name.underscore}" },
  )

  def email_from(topic = "")
    community_name = if topic.present?
                       "#{Settings::Community.community_name} #{topic}"
                     else
                       Settings::Community.community_name
                     end

    "#{community_name} <#{SiteConfig.email_addresses[:default]}>"
  end

  def generate_unsubscribe_token(id, email_type)
    Rails.application.message_verifier(:unsubscribe).generate({
                                                                user_id: id,
                                                                email_type: email_type.to_sym,
                                                                expires_at: 31.days.from_now
                                                              })
  end

  def use_custom_host
    ActionMailer::Base.default_url_options[:host] = SiteConfig.app_domain
  end
end
