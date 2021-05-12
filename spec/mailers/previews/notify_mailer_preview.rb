# Preview all emails at http://localhost:3000/rails/mailers/notify_mailer
class NotifyMailerPreview < ActionMailer::Preview
  def new_reply_email
    NotifyMailer.with(comment: Comment.first).new_reply_email
  end

  def new_follower_email
    follow = User.first.follow(User.last)
    NotifyMailer.with(follow: follow).new_follower_email
  end

  def unread_notifications_email
    NotifyMailer.with(user: User.last).unread_notifications_email
  end

  def new_comment_mention_email
    mention = Mention.find_or_create_by(user: User.find(1), mentionable: Comment.find(1))
    NotifyMailer.with(mention: mention).new_mention_email
  end

  def new_article_mention_email
    mention = Mention.find_or_create_by(user: User.find(1), mentionable: Article.find(1))
    NotifyMailer.with(mention: mention).new_mention_email
  end

  def video_upload_complete_email
    NotifyMailer.with(article: Article.last).video_upload_complete_email
  end

  def new_badge_email
    badge_achievement = BadgeAchievement.find_or_create_by(
      user: User.find(1),
      badge: Badge.find(1),
      rewarder: User.find(2),
      rewarding_context_message: "You made it!",
    )
    NotifyMailer.with(badge_achievement: badge_achievement).new_badge_email
  end

  def channel_invite_email
    user = User.first
    membership = ChatChannelMembership.last
    NotifyMailer.with(membership: membership, inviter: user).channel_invite_email
  end

  def tag_moderator_confirmation_email
    NotifyMailer.with(user: User.first, tag: Tag.find(1), channel_slug: nil).tag_moderator_confirmation_email
  end

  def trusted_role_email
    NotifyMailer.with(user: User.first).trusted_role_email
  end

  def feedback_message_resolution_email
    # change email_body text when you need to see a different version
    @user = User.first
    email_body = <<~HEREDOC
      Hi [*USERNAME*],

      We wanted to say thank you for flagging a [comment/post] that was in violation of the dev.to
      code of conduct and terms of service. Your action has helped us continue our work of
      fostering an open and welcoming community.

      We've also removed the offending posts and reached out to the offender(s).

      Thanks again for being a great part of the community.

      PBJ
    HEREDOC
    params = {
      email_to: @user.email,
      email_subject: "Courtesy notice from #{SiteConfig.community_name}",
      email_body: email_body,
      email_type: "Reporter",
      feedback_message_id: rand(100)
    }
    NotifyMailer.with(params).feedback_message_resolution_email
  end

  def new_message_email
    NotifyMailer.with(message: Message.last).new_message_email
  end

  def account_deleted_email
    user = User.last
    NotifyMailer.with(name: user.name, email: user.email).account_deleted_email
  end

  def export_email
    NotifyMailer.with(user: User.last, attachment: "attachment").export_email
  end
end
