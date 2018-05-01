class MembershipMailer < ApplicationMailer
  default from: "DEV Members <members@dev.to>"

  def new_membership_subscription_email(user, subscription_type)
    @user = user
    @subscription_type = subscription_type
    mail(to: @user.email, subject: "Thanks for subscribing!")
  end

  def subscription_update_confirm_email(user)
    @user = user
    mail(to: @user.email, subject: "Your subscription has been updated.")
  end

  def subscription_cancellation_email(user)
    @user = user
    mail(to: @user.email, subject: "Sorry to lose you.")
  end
end
