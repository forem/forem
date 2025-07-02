class NotifyMailer < ApplicationMailer
  has_history extra: lambda {
    {
      feedback_message_id: params[:feedback_message_id],
      utm_campaign: params[:email_type]
    }
  }, only: :feedback_message_resolution_email

  def new_reply_email
    @comment = params[:comment]
    sanitized_comment = ApplicationController.helpers.sanitize(@comment.processed_html,
                                                               scrubber: CommentEmailScrubber.new)
    @truncated_comment = ApplicationController.helpers.truncate(sanitized_comment, length: 500, separator: " ",
                                                                                   omission: "...", escape: false)

    @user = @comment.parent_user
    return if @user.email.blank?
    return if RateLimitChecker.new.limit_by_email_recipient_address(@user.email)

    @unsubscribe = generate_unsubscribe_token(@user.id, :email_comment_notifications)

    # Don't send the email if there's no visible contents
    # Placed here to allow the preview to continue to work
    return if @truncated_comment.blank?

    mail(to: @user.email,
         subject: I18n.t("mailers.notify_mailer.new_reply", name: @comment.user.name, type: @comment.parent_type))
  rescue StandardError => e
    Honeybadger.notify(e)
  end

  def new_follower_email
    follow = params[:follow]

    @user = follow.followable
    return if RateLimitChecker.new.limit_by_email_recipient_address(@user.email)

    @follower = follow.follower
    @unsubscribe = generate_unsubscribe_token(@user.id, :email_follower_notifications)

    mail(to: @user.email, subject: "#{@follower.name} #{subjects[__method__]}")
  end

  def new_mention_email
    @mention = params[:mention]
    @user = User.find(@mention.user_id)
    return if RateLimitChecker.new.limit_by_email_recipient_address(@user.email)

    @mentioner = User.find(@mention.mentionable.user_id)
    @mentionable = @mention.mentionable
    @mentionable_type = @mention.decorate.formatted_mentionable_type

    @unsubscribe = generate_unsubscribe_token(@user.id, :email_mention_notifications)

    mail(to: @user.email,
         subject: I18n.t("mailers.notify_mailer.new_mention", name: @mentioner.name, type: @mentionable_type))
  end

  def unread_notifications_email
    @user = params[:user]
    return if RateLimitChecker.new.limit_by_email_recipient_address(@user.email)

    @unread_notifications_count = @user.notifications.unread.count
    @unsubscribe = generate_unsubscribe_token(@user.id, :email_unread_notifications)
    subject = I18n.t("mailers.notify_mailer.unread_notifications", count: @unread_notifications_count,
                                                                   community: Settings::Community.community_name)
    mail(to: @user.email, subject: subject)
  end

  def video_upload_complete_email
    @article = params[:article]
    @user = @article.user
    mail(to: @user.email, subject: I18n.t("mailers.notify_mailer.video_upload"))
  end

  def new_badge_email
    @badge_achievement = params[:badge_achievement]
    @user = @badge_achievement.user
    @badge = @badge_achievement.badge
    @unsubscribe = generate_unsubscribe_token(@user.id, :email_badge_notifications)

    mail(to: @user.email, subject: I18n.t("mailers.notify_mailer.new_badge"))
  end

  def feedback_response_email
    mail(to: params[:email_to],
         subject: I18n.t("mailers.notify_mailer.feedback",
                         community: Settings::Community.community_name))
  end

  def feedback_message_resolution_email
    @user = User.find_by(email: params[:email_to])
    @email_body = params[:email_body]

    mail(to: params[:email_to], subject: params[:email_subject])
  end

  def user_contact_email
    @user = User.find(params[:user_id])
    @email_body = params[:email_body]

    mail(to: @user.email, subject: params[:email_subject])
  end

  def account_deleted_email
    @name = params[:name]

    subject = I18n.t("mailers.notify_mailer.account_deleted", community: Settings::Community.community_name)
    mail(to: params[:email], subject: subject)
  end

  def organization_deleted_email
    @name = params[:name]
    @org_name = params[:org_name]

    subject = I18n.t("mailers.notify_mailer.org_deleted", community: Settings::Community.community_name)
    mail(to: params[:email], subject: subject)
  end

  def account_deletion_requested_email
    user = params[:user]
    @name = user.name
    @token = params[:token]

    subject = I18n.t("mailers.notify_mailer.deletion_requested", community: Settings::Community.community_name)
    mail(to: user.email, subject: subject)
  end

  def export_email
    attachment = params[:attachment]

    export_filename = "devto-export-#{Date.current.iso8601}.zip"
    attachments[export_filename] = attachment
    mail(to: params[:email], subject: I18n.t("mailers.notify_mailer.export"))
  end

  def tag_moderator_confirmation_email
    @user = params[:user]
    @tag = params[:tag]
    @channel_slug = params[:channel_slug]

    subject = I18n.t("mailers.notify_mailer.moderator", tag_name: @tag.name)
    mail(to: @user.email, subject: subject)
  end

  def trusted_role_email
    @user = params[:user]

    subject = I18n.t("mailers.notify_mailer.trusted",
                     community: Settings::Community.community_name)
    mail(to: @user.email, subject: subject)
  end

  def base_subscriber_role_email
    @user = params[:user]

    subject = I18n.t("mailers.notify_mailer.base_subscriber",
                     community: Settings::Community.community_name)
    mail(to: @user.email, subject: subject)
  end

  def subjects
    {
      new_follower_email: I18n.t("mailers.notify_mailer.new_follower",
                                 community: Settings::Community.community_name).freeze
    }.freeze
  end
end
