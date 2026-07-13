class EmailSubscriptionsController < ApplicationController
  def unsubscribe
    verified_params = Rails.application.message_verifier(:unsubscribe).verify(params[:ut]).with_indifferent_access

    expires_at = verified_params[:expires_at]
    expires_at = Time.zone.parse(expires_at) if expires_at.is_a?(String)

    if expires_at && expires_at > Time.current
      user = User.find(verified_params[:user_id])
      email_type = verified_params[:email_type]&.to_sym
      user.notification_setting.update(email_type => false)
      @email_type = preferred_email_name.fetch(email_type,
                                               I18n.t("email_subscriptions_controller.this_list")).call
    else
      render "invalid_token"
    end
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    not_found
  end

  def stay_subscribed
    verified = Rails.application.message_verifier(:email_retain).verify(params[:rt]).with_indifferent_access
    expires_at = verified[:expires_at]
    expires_at = Time.zone.parse(expires_at) if expires_at.is_a?(String)

    if expires_at && expires_at > Time.current
      setting = User.find(verified[:user_id]).notification_setting
      if setting && setting.email_reengagement_confirmed_at.nil?
        setting.update(email_reengagement_confirmed_at: Time.current)
      end
      render "stay_subscribed"
    else
      render "invalid_token"
    end
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    not_found
  end

  def preferred_email_name
    {
      email_digest_periodic: lambda {
                               I18n.t("email_subscriptions_controller.digest_emails",
                                      community: Settings::Community.community_name)
                             },
      email_comment_notifications: -> { I18n.t("email_subscriptions_controller.comment_notifications") },
      email_follower_notifications: -> { I18n.t("email_subscriptions_controller.follower_notifications") },
      email_mention_notifications: -> { I18n.t("email_subscriptions_controller.mention_notifications") },
      email_unread_notifications: -> { I18n.t("email_subscriptions_controller.unread_notifications") },
      email_badge_notifications: -> { I18n.t("email_subscriptions_controller.badge_notifications") },
      email_newsletter: -> { I18n.t("email_subscriptions_controller.newsletter") }
    }.freeze
  end
end
