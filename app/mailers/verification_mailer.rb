class VerificationMailer < ApplicationMailer
  default from: lambda {
    I18n.t("mailers.verification_mailer.from", community: Settings::Community.community_name,
                                               email: ForemInstance.from_email_address)
  }

  def account_ownership_verification_email
    @user = User.find(params[:user_id])
    email_authorization = EmailAuthorization.create!(user: @user, type_of: "account_ownership")
    @confirmation_token = email_authorization.confirmation_token

    mail(to: @user.email,
         subject: I18n.t("mailers.verification_mailer.verify_ownership",
                         community: Settings::Community.community_name))
  end

  def magic_link
    @user = User.find(params[:user_id])
    mail(
      to: @user.email,
      subject: "Sign in to #{Settings::Community.community_name} with a magic code",
      from: "#{Settings::Community.community_name} <#{ForemInstance.from_email_address}>",
      reply_to: ForemInstance.reply_to_email_address
    )
  end
end
