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

  def video_upload_complete_email
    NotifyMailer.video_upload_complete_email(Article.last)
  end

  def new_badge_email
    NotifyMailer.new_badge_email(BadgeAchievement.first)
  end

  def new_report_email
    NotifyMailer.new_report_email(FeedbackMessage.first)
  end
end
