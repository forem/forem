class VerificationMailer < ApplicationMailer
  include Rails.application.routes.url_helpers

  default from: lambda {
    I18n.t("mailers.verification_mailer.from", community: Settings::Community.community_name(subforem_id: @subforem_id),
                                               email: ForemInstance.from_email_address)
  }

  # Security emails must not get link tracking (see save_ahoy_options no-op /
  # spam-filter risk); the same applies on the Customer.io route.
  before_action { customerio_delivery_options(tracked: false) }

  def account_ownership_verification_email
    @user = User.find(params[:user_id])
    email_authorization = EmailAuthorization.create!(user: @user, type_of: "account_ownership")
    @confirmation_token = email_authorization.confirmation_token

    community_name = Settings::Community.community_name(subforem_id: @subforem_id)
    verification_url = ApplicationController.helpers.app_url(
      verify_email_authorizations_path(confirmation_token: @confirmation_token, username: @user.username),
    )

    customerio_delivery_options(
      transactional_message_id: "dev_account_ownership_verification",
      message_data: {
        "verification_url" => verification_url,
        "username" => @user.username,
        "community_name" => community_name
      },
    )

    mail(to: @user.email,
         subject: I18n.t("mailers.verification_mailer.verify_ownership",
                         community: community_name))
  end

  def magic_link
    @user = User.find(params[:user_id])
    community_name = Settings::Community.community_name(subforem_id: @subforem_id)

    customerio_delivery_options(
      transactional_message_id: "dev_magic_link",
      message_data: {
        "sign_in_token" => @user.sign_in_token,
        "magic_link_url" => magic_link_url(@user.sign_in_token),
        "name" => @user.name,
        "community_name" => community_name
      },
    )

    mail(
      to: @user.email,
      subject: "Sign in to #{community_name} with a magic code",
      from: "#{community_name} <#{ForemInstance.from_email_address}>",
      reply_to: ForemInstance.reply_to_email_address
    )
  end
end
