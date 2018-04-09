class ApplicationMailer < ActionMailer::Base
  default from: "The DEV Community <yo@dev.to>"
  layout "mailer"

  def generate_unsubscribe_token(id, email_type)
    Rails.application.message_verifier(:unsubscribe).generate(
      user_id: id,
      email_type: email_type.to_sym,
      expires_at: Time.now + 2.days,
    )
  end
end
