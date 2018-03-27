# Preview all emails at http://localhost:3000/rails/mailers/notify_mailer
class NotifyMailerPreview < ActionMailer::Preview
  def new_reply_email
    NotifyMailer.new_reply_email(Comment.find(1))
  end

  def new_follower_email
    NotifyMailer.new_follower_email(Follow.last)
  end

  def unread_notifications_email
    NotifyMailer.unread_notifications_email(User.last)
  end

  def new_mention_email
    NotifyMailer.new_mention_email(Mention.last)
  end

  def new_membership_subscription_email
    NotifyMailer.new_membership_subscription_email(User.last, "level_2_member")
  end

  def subscription_update_confirm_email
    NotifyMailer.subscription_update_confirm_email(User.last)
  end

  def subscription_cancellation_email
    NotifyMailer.subscription_cancellation_email(User.last)
  end

  def scholarship_awarded_email
    NotifyMailer.scholarship_awarded_email(User.last)
  end

  def digest_email
    NotifyMailer.digest_email(User.last, Article.all)
  end
end
