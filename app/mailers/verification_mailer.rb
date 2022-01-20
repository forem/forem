class VerificationMailer < ApplicationMailer
  default from: lambda {
    I18n.t("mailers.verification_mailer.from", community: Settings::Community.community_name,
                                               email: ForemInstance.email)
  }

  def account_ownership_verification_email
    @user = User.find(params[:user_id])
    email_authorization = EmailAuthorization.create!(user: @user, type_of: "account_ownership")
    @confirmation_token = email_authorization.confirmation_token

    mail(to: @user.email,
         subject: I18n.t("mailers.verification_mailer.verify_ownership",
                         community: Settings::Community.community_name))
  end
end
