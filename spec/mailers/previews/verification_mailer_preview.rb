# Preview all emails at http://localhost:3000/rails/mailers/verification_mailer
class VerificationMailerPreview < ActionMailer::Preview
  def account_ownership_verification_email
    params = { user_id: User.last.id }
    VerificationMailer.account_ownership_verification_email(params)
  end
end
