class VerificationMailer < ApplicationMailer
  default from: -> { "#{ApplicationConfig['COMMUNITY_NAME']} Email Verification <#{SiteConfig.email_addresses[:default]}>" }

  def account_ownership_verification_email(params)
    @user = User.find(params[:user_id])
    email_authorization = EmailAuthorization.create(user: @user, type_of: "account_ownership")
    @confirmation_token = email_authorization.confirmation_token
    mail(to: @user.email, subject: "Verify Your #{ApplicationConfig['COMMUNITY_NAME']} Account Ownership")
  end
end
