# Preview all emails at http://localhost:3000/rails/mailers/verification_mailer
class VerificationMailerPreview < ActionMailer::Preview
  def account_ownership_verification_email
    VerificationMailer.with(user_id: User.last.id).account_ownership_verification_email
  end

  def magic_link
    @user = User.last
    @user.update_column(:sign_in_token, "098738") if @user.sign_in_token.blank?
    VerificationMailer.with(user_id: @user.id).magic_link
  end
end
