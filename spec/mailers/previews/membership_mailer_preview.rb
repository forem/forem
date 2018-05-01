class MembershipMailerPreview < ActionMailer::Preview
  def new_membership_subscription_email
    MembershipMailer.new_membership_subscription_email(User.last, "level_2_member")
  end

  def subscription_update_confirm_email
    MembershipMailer.subscription_update_confirm_email(User.last)
  end

  def subscription_cancellation_email
    MembershipMailer.subscription_cancellation_email(User.last)
  end
end
