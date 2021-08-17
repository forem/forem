class EmailSubscriptionsController < ApplicationController
  def unsubscribe
    verified_params = Rails.application.message_verifier(:unsubscribe).verify(params[:ut])

    if verified_params[:expires_at] > Time.current
      user = User.find(verified_params[:user_id])
      user.notification_setting.update(verified_params[:email_type] => false)
      @email_type = preferred_email_name.fetch(verified_params[:email_type], "this list")
    else
      render "invalid_token"
    end
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    not_found
  end

  def preferred_email_name
    {
      email_digest_periodic: "#{Settings::Community.community_name} digest emails",
      email_comment_notifications: "comment notifications",
      email_follower_notifications: "follower notifications",
      email_mention_notifications: "mention notifications",
      email_connect_messages: "#{Settings::Community.community_name} connect messages",
      email_unread_notifications: "unread notifications",
      email_badge_notifications: "badge notifications"
    }.freeze
  end
end
