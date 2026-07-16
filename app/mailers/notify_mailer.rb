class NotifyMailer < ApplicationMailer
  include Rails.application.routes.url_helpers

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

    customerio_delivery_options(
      transactional_message_id: "dev_new_reply_email",
      message_data: {
        "commenter_name" => @comment.user.name,
        "parent_type" => @comment.parent_type,
        "comment_html" => @truncated_comment,
        "comment_url" => URL.comment(@comment),
        "article_or_parent_title" => @comment.commentable&.title || "Content No Longer Available",
        "unsubscribe_url" => email_subscriptions_unsubscribe_url(ut: @unsubscribe)
      },
    )

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

    customerio_delivery_options(
      transactional_message_id: "dev_new_follower_email",
      message_data: {
        "follower_name" => @follower.name,
        "follower_profile_url" => URL.user(@follower),
        "unsubscribe_url" => email_subscriptions_unsubscribe_url(ut: @unsubscribe)
      },
    )

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

    customerio_delivery_options(
      transactional_message_id: "dev_new_mention_email",
      message_data: {
        "mentioner_name" => @mentioner.name,
        "mentionable_type" => @mentionable_type,
        "mention_url" => URL.url(@mention.mentionable.path, RequestStore.store[:subforem_domain]),
        "unsubscribe_url" => email_subscriptions_unsubscribe_url(ut: @unsubscribe)
      },
    )

    mail(to: @user.email,
         subject: I18n.t("mailers.notify_mailer.new_mention", name: @mentioner.name, type: @mentionable_type))
  end

  def unread_notifications_email
    @user = params[:user]
    return if RateLimitChecker.new.limit_by_email_recipient_address(@user.email)

    @unread_notifications_count = @user.notifications.unread.count
    @unsubscribe = generate_unsubscribe_token(@user.id, :email_unread_notifications)
    community_name = Settings::Community.community_name(subforem_id: @subforem_id)
    subject = I18n.t("mailers.notify_mailer.unread_notifications", count: @unread_notifications_count,
                                                                   community: community_name)

    customerio_delivery_options(
      transactional_message_id: "dev_unread_notifications_email",
      message_data: {
        "unread_count" => @unread_notifications_count,
        "notifications_url" => URL.url("/notifications", RequestStore.store[:subforem_domain]),
        "community_name" => community_name,
        "unsubscribe_url" => email_subscriptions_unsubscribe_url(ut: @unsubscribe)
      },
    )

    mail(to: @user.email, subject: subject)
  end

  def video_upload_complete_email
    @article = params[:article]
    @user = @article.user

    customerio_delivery_options(
      transactional_message_id: "dev_video_upload_complete",
      message_data: {
        "article_title" => @article.title,
        "article_url" => "#{ApplicationController.helpers.article_url(@article)}/edit"
      },
    )

    mail(to: @user.email, subject: I18n.t("mailers.notify_mailer.video_upload"))
  end

  def new_badge_email
    @badge_achievement = params[:badge_achievement]
    @user = @badge_achievement.user
    @badge = @badge_achievement.badge
    @unsubscribe = generate_unsubscribe_token(@user.id, :email_badge_notifications)
    badge_description = @badge.description if @badge_achievement.include_default_description

    customerio_delivery_options(
      transactional_message_id: "dev_new_badge_email",
      message_data: {
        "badge_name" => @badge.title,
        "badge_description" => badge_description,
        "badge_image_url" => @badge.badge_image_url,
        "unsubscribe_url" => email_subscriptions_unsubscribe_url(ut: @unsubscribe)
      },
    )

    mail(to: @user.email, subject: I18n.t("mailers.notify_mailer.new_badge"))
  end

  def feedback_response_email
    community_name = Settings::Community.community_name(subforem_id: @subforem_id)

    customerio_delivery_options(
      transactional_message_id: "dev_feedback_response",
      message_data: {
        "community_name" => community_name
      },
    )

    mail(to: params[:email_to],
         subject: I18n.t("mailers.notify_mailer.feedback", community: community_name))
  end

  def feedback_message_resolution_email
    @user = User.find_by(email: params[:email_to])
    @email_body = params[:email_body]

    customerio_delivery_options(
      transactional_message_id: "dev_feedback_resolution",
      message_data: {
        "email_body" => @email_body
      },
    )

    mail(to: params[:email_to], subject: params[:email_subject])
  end

  def user_contact_email
    @user = User.find(params[:user_id])
    @email_body = params[:email_body]

    customerio_delivery_options(
      transactional_message_id: "dev_user_contact",
      message_data: {
        "email_body" => @email_body
      },
    )

    mail(to: @user.email, subject: params[:email_subject])
  end

  def account_deleted_email
    @name = params[:name]
    community_name = Settings::Community.community_name(subforem_id: @subforem_id)

    customerio_delivery_options(
      transactional_message_id: "dev_account_deleted",
      message_data: {
        "name" => @name,
        "community_name" => community_name
      },
    )

    subject = I18n.t("mailers.notify_mailer.account_deleted", community: community_name)
    mail(to: params[:email], subject: subject)
  end

  def organization_deleted_email
    @name = params[:name]
    @org_name = params[:org_name]
    community_name = Settings::Community.community_name(subforem_id: @subforem_id)

    customerio_delivery_options(
      transactional_message_id: "dev_organization_deleted",
      message_data: {
        "name" => @name,
        "org_name" => @org_name,
        "community_name" => community_name
      },
    )

    subject = I18n.t("mailers.notify_mailer.org_deleted", community: community_name)
    mail(to: params[:email], subject: subject)
  end

  def account_deletion_requested_email
    user = params[:user]
    @name = user.name
    @token = params[:token]
    community_name = Settings::Community.community_name(subforem_id: @subforem_id)

    customerio_delivery_options(
      transactional_message_id: "dev_account_deletion_requested",
      message_data: {
        "name" => @name,
        "confirmation_url" => user_confirm_destroy_url(@token),
        "community_name" => community_name
      },
    )

    subject = I18n.t("mailers.notify_mailer.deletion_requested", community: community_name)
    mail(to: user.email, subject: subject)
  end

  def export_email
    attachment = params[:attachment]
    community_name = Settings::Community.community_name(subforem_id: @subforem_id)

    export_filename = "devto-export-#{Date.current.iso8601}.zip"
    attachments[export_filename] = attachment

    customerio_delivery_options(
      transactional_message_id: "dev_export_email",
      message_data: {
        "community_name" => community_name
      },
    )

    mail(to: params[:email], subject: I18n.t("mailers.notify_mailer.export"))
  end

  def tag_moderator_confirmation_email
    @user = params[:user]
    @tag = params[:tag]
    @channel_slug = params[:channel_slug]
    community_name = Settings::Community.community_name(subforem_id: @subforem_id)

    customerio_delivery_options(
      transactional_message_id: "dev_tag_mod_confirmation",
      message_data: {
        "tag_name" => @tag.name,
        "tag_url" => URL.tag(@tag),
        "community_moderation_url" => community_moderation_url,
        "community_name" => community_name
      },
    )

    subject = I18n.t("mailers.notify_mailer.moderator", tag_name: @tag.name)
    mail(to: @user.email, subject: subject)
  end

  def subforem_moderator_confirmation_email
    @user = params[:user]
    @subforem = params[:subforem]
    community_name = Settings::Community.community_name(subforem_id: @subforem_id)

    customerio_delivery_options(
      transactional_message_id: "dev_subforem_mod_confirmation",
      message_data: {
        "subforem_domain" => @subforem.domain,
        "subforem_url" => "https://#{@subforem.domain}",
        "community_moderation_url" => community_moderation_url,
        "community_name" => community_name
      },
    )

    subject = I18n.t("mailers.notify_mailer.subforem_moderator", subforem_name: @subforem.domain)
    mail(to: @user.email, subject: subject)
  end

  def trusted_role_email
    @user = params[:user]
    community_name = Settings::Community.community_name(subforem_id: @subforem_id)

    customerio_delivery_options(
      transactional_message_id: "dev_trusted_role",
      message_data: {
        "community_name" => community_name,
        "trusted_member_guide_url" => trusted_member_guide_url
      },
    )

    subject = I18n.t("mailers.notify_mailer.trusted", community: community_name)
    mail(to: @user.email, subject: subject)
  end

  def base_subscriber_role_email
    @user = params[:user]
    community_name = Settings::Community.community_name(subforem_id: @subforem_id)

    customerio_delivery_options(
      transactional_message_id: "dev_base_subscriber_role",
      message_data: {
        "community_name" => community_name
      },
    )

    subject = I18n.t("mailers.notify_mailer.base_subscriber", community: community_name)
    mail(to: @user.email, subject: subject)
  end

  def subjects
    {
      new_follower_email: I18n.t("mailers.notify_mailer.new_follower",
                                 community: Settings::Community.community_name(subforem_id: @subforem_id)).freeze
    }.freeze
  end

  private

  # Mirrors the conditional "Trusted Member Guide" link rendered by
  # trusted_role_email.html.erb -- only present when a "trusted-member" Page
  # exists -- so the Customer.io template can reproduce the same condition.
  def trusted_member_guide_url
    return unless Page.find_by(slug: "trusted-member")

    ApplicationController.helpers.app_url("trusted-member")
  end
end
