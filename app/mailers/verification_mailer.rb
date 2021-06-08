class VerificationMailer < ApplicationMailer
  default from: lambda {
    "#{Settings::Community.community_name} Email Verification <#{Settings::General.email_addresses[:default]}>"
  }

  def account_ownership_verification_email
    @user = User.find(params[:user_id])
    email_authorization = EmailAuthorization.create!(user: @user, type_of: "account_ownership")
    @confirmation_token = email_authorization.confirmation_token

    mail(to: @user.email, subject: "Verify Your #{Settings::Community.community_name} Account Ownership")
  end
end
