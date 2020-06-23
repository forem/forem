# Preview all emails at http://localhost:3000/rails/mailers/verification_mailer
class VerificationMailerPreview < ActionMailer::Preview
  def account_ownership_verification_email
    VerificationMailer.with(user_id: User.last.id).account_ownership_verification_email
  end
end
