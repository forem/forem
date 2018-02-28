class NotifyMailer < ApplicationMailer

  def new_reply_email(comment)
    @user = if Rails.env.development?
      User.first
    else
      comment.parent_user
    end
    return if RateLimitChecker.new.limit_by_email_recipient_address(@user.email)
    @comment = comment
    mail(to: @user.email, subject: "#{@comment.user.name} replied to your #{@comment.parent_type}") do |format|
      format.html { render "layouts/mailer" }
      format.text { render plain: "#{@comment.user.name} replied to your #{@comment.parent_type}:\n\n#{ActionController::Base.helpers.strip_tags(comment.processed_html.html_safe)}\n\nView now: https://dev.to#{comment.path}" }
    end
  end

  def new_follower_email(follow)
    @user = if Rails.env.development?
      User.first
    else
      follow.followable
    end
    return if RateLimitChecker.new.limit_by_email_recipient_address(@user.email)
    @follower = follow.follower

    mail(to: @user.email, subject: "#{@follower.name} just followed you on dev.to") do |format|
      format.html { render 'layouts/mailer' }
      format.text { render plain: "#{@follower.name} just followed you. When someone follows you, your posts will be prioritized on their personalized home feed. This new feature is one step towards offering a more customized experience." }
    end
  end

  def new_mention_email(mention)
    @user = User.find(mention.user_id)
    return if RateLimitChecker.new.limit_by_email_recipient_address(@user.email)
    @mentioner = User.find(mention.mentionable.user_id)
    @mentionable = mention.mentionable
    @mention = mention

    mail(to: @user.email, subject: "#{@mentioner.name} just mentioned you!") do |format|
      format.html { render 'layouts/mailer' }
      format.text { render plain: "#{@mentioner.name} just mentioned you in their #{mention.mentionable_type.downcase}\n\n#{ActionController::Base.helpers.strip_tags(@mentionable.processed_html.html_safe)}\n\nView now: https://dev.to#{mention.mentionable.path}" }
    end
  end

  def unread_notifications_email(user)
    @user = if Rails.env.development?
      User.first
    else
      user
    end
    return if RateLimitChecker.new.limit_by_email_recipient_address(@user.email)
    @unread_notifications_count = NotificationCounter.new(@user).unread_notification_count
    mail(to: @user.email, subject: "🔥 You have #{@unread_notifications_count} unread notifications on dev.to") do |format|
      format.html { render 'layouts/mailer' }
      format.text { render plain: "Visit https://dev.to/notifications to read all of your notifications" }
    end
  end

  def new_membership_subscription_email(user,subscription_type)
    @user = if Rails.env.development?
              User.first
            else
              user
            end
    @subscription_type = subscription_type
    mail(from: "DEV Members <members@dev.to>", to: @user.email, subject: "Thanks for subscribing!") do |format|
      format.html { render "layouts/mailer" }
      format.text { render plain: "Visit https://dev.to/settings/membership for full details" }
    end
  end

  def subscription_update_confirm_email(user)
    @user = if Rails.env.development?
              User.first
            else
              user
            end
    @update_subscription = true
    mail(from: "DEV Members <members@dev.to>", to: @user.email, subject: "Your subscription has been updated.") do |format|
      format.html { render "layouts/mailer" }
      format.text { render plain: "Visit https://dev.to/settings/membership for updated details" }
    end
  end

  def subscription_cancellation_email(user)
    @user = if Rails.env.development?
              User.first
            else
              user
            end
    @cancel_subscription = true
    mail(from: "members@dev.to", to: @user.email, subject: "Sorry to lose you.") do |format|
      format.html { render "layouts/mailer" }
      format.text { render plain: "    If you could send feedback to yo@dev.to to help us improve it would be much appreciated." }
    end
  end

  def scholarship_awarded_email(user)
    @user = if Rails.env.development?
              User.first
            else
              user
            end
    @scholarship_awarded = true
    mail(from: "members@dev.to", to: @user.email, subject: "Congrats on your DEV Scholarship!") do |format|
      format.html { render "layouts/mailer" }
      format.text { render plain: "Congratulations on your dev.to Scholarship! See https://dev.to/settings/misc for updated details" }
    end
  end
end
