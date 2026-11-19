# Preview all emails at http://localhost:3000/rails/mailers/verification_mailer
class VerificationMailerPreview < ActionMailer::Preview
  def account_ownership_verification_email
    VerificationMailer.with(user_id: User.last.id).account_ownership_verification_email
  end

  def magic_link
    @user = User.last
    if @user.sign_in_token.blank? || @user.sign_in_token_sent_at.blank?
      @user.update_columns(sign_in_token: "098738", sign_in_token_sent_at: Time.current)
    end
    VerificationMailer.with(user_id: @user.id).magic_link
  end
end
