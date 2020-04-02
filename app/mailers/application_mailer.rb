class ApplicationMailer < ActionMailer::Base
  layout "mailer"

  default(
    from: -> { "DEV Community <#{SiteConfig.default_site_email}>" },
    template_path: ->(mailer) { "mailers/#{mailer.class.name.underscore}" },
  )

  def generate_unsubscribe_token(id, email_type)
    Rails.application.message_verifier(:unsubscribe).generate(
      user_id: id,
      email_type: email_type.to_sym,
      expires_at: 31.days.from_now,
    )
  end
end
