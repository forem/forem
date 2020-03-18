# Preview all emails at http://localhost:3000/rails/mailers/notify_mailer
class NotifyMailerPreview < ActionMailer::Preview
  def new_reply_email
    NotifyMailer.new_reply_email(Comment.find(1))
  end

  def new_follower_email
    follow = User.first.follow(User.last)
    NotifyMailer.new_follower_email(follow)
  end

  def unread_notifications_email
    NotifyMailer.unread_notifications_email(User.last)
  end

  def new_mention_email
    mention = Mention.find_or_create_by(user: User.find(1), mentionable: Comment.find(1))
    NotifyMailer.new_mention_email(mention)
  end

  def video_upload_complete_email
    NotifyMailer.video_upload_complete_email(Article.last)
  end

  def new_badge_email
    badge_achievement = BadgeAchievement.find_or_create_by(
      user: User.find(1),
      badge: Badge.find(1),
      rewarder: User.find(2),
      rewarding_context_message: "You made it!",
    )
    NotifyMailer.new_badge_email(badge_achievement)
  end

  def tag_moderator_confirmation_email
    NotifyMailer.tag_moderator_confirmation_email(User.first, "discuss")
  end

  def trusted_role_email
    NotifyMailer.trusted_role_email(User.first)
  end

  def feedback_message_resolution_email
    # change email_body text when you need to see a different version
    @user = User.first
    email_body = <<~HEREDOC
      Hi [*USERNAME*],

      We wanted to say thank you for flagging a [comment/post] that was in violation of the dev.to code of conduct and terms of service. Your action has helped us continue our work of fostering an open and welcoming community.

      We've also removed the offending posts and reached out to the offender(s).

      Thanks again for being a great part of the community.

      PBJ
    HEREDOC
    params = {
      email_to: @user.email,
      email_subject: "Courtesy notice from dev.to",
      email_body: email_body,
      email_type: "Reporter",
      feedback_message_id: rand(100)
    }
    NotifyMailer.feedback_message_resolution_email(params)
  end

  def new_message_email
    NotifyMailer.new_message_email(Message.last)
  end

  def account_deleted_email
    NotifyMailer.account_deleted_email(User.last)
  end

  def export_email
    NotifyMailer.export_email(User.last, "attachment")
  end
end
