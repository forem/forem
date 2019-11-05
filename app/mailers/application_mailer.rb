class ApplicationMailer < ActionMailer::Base
  default from: "DEV Community <#{ApplicationConfig['DEFAULT_SITE_EMAIL']}>"
  layout "mailer"
  default template_path: ->(mailer) { "mailers/#{mailer.class.name.underscore}" }

  def generate_unsubscribe_token(id, email_type)
    Rails.application.message_verifier(:unsubscribe).generate(
      user_id: id,
      email_type: email_type.to_sym,
      expires_at: 31.days.from_now,
    )
  end
end
