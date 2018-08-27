class NotifyMailer < ApplicationMailer
  def new_reply_email(comment)
    @user = comment.parent_user
    return if RateLimitChecker.new.limit_by_email_recipient_address(@user.email)
    @unsubscribe = generate_unsubscribe_token(@user.id, :email_comment_notifications)
    @comment = comment
    mail(to: @user.email, subject: "#{@comment.user.name} replied to your #{@comment.parent_type}")
  end

  def new_follower_email(follow)
    @user = follow.followable
    return if RateLimitChecker.new.limit_by_email_recipient_address(@user.email)
    @follower = follow.follower
    @unsubscribe = generate_unsubscribe_token(@user.id, :email_follower_notifications)

    mail(to: @user.email, subject: "#{@follower.name} just followed you on dev.to")
  end

  def new_mention_email(mention)
    @user = User.find(mention.user_id)
    return if RateLimitChecker.new.limit_by_email_recipient_address(@user.email)
    @mentioner = User.find(mention.mentionable.user_id)
    @mentionable = mention.mentionable
    @mention = mention
    @unsubscribe = generate_unsubscribe_token(@user.id, :email_mention_notifications)

    mail(to: @user.email, subject: "#{@mentioner.name} just mentioned you!")
  end

  def unread_notifications_email(user)
    @user = user
    return if RateLimitChecker.new.limit_by_email_recipient_address(@user.email)
    @unread_notifications_count = NotificationCounter.new(@user).unread_notification_count
    @unsubscribe = generate_unsubscribe_token(@user.id, :email_unread_notifications)
    subject = "🔥 You have #{@unread_notifications_count} unread notifications on dev.to"
    mail(to: @user.email, subject: subject)
  end

  def video_upload_complete_email(article)
    @article = article
    @user = @article.user
    mail(to: @user.email, subject: "Your video upload is complete")
  end

  def new_badge_email(badge_achievement)
    @badge_achievement = badge_achievement
    @user = @badge_achievement.user
    @badge = @badge_achievement.badge
    mail(to: @user.email, subject: "You just got a badge")
  end

  def feedback_message_resolution_email(params)
    @user = User.find_by(email: params[:email_to])
    @email_body = params[:email_body]
    track utm_campaign: params[:email_type]
    track extra: { feedback_message_id: params[:feedback_message_id] }
    mail(to: params[:email_to], subject: params[:email_subject])
  end
end
