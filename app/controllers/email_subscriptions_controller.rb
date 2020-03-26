class EmailSubscriptionsController < ApplicationController
  PREFERRED_EMAIL_NAME = {
    email_digest_periodic: "DEV digest emails",
    email_comment_notifications: "comment notifications",
    email_follower_notifications: "follower notifications",
    email_mention_notifications: "mention notifications",
    email_connect_messages: "DEV connect messages",
    email_unread_notifications: "unread notifications",
    email_badge_notifications: "badge notifications"
  }.freeze

  def unsubscribe
    verified_params = Rails.application.message_verifier(:unsubscribe).verify(params[:ut])

    if verified_params[:expires_at] > Time.current
      user = User.find(verified_params[:user_id])
      user.update(verified_params[:email_type] => false)
      @email_type = PREFERRED_EMAIL_NAME.fetch(verified_params[:email_type], "this list")
    else
      render "invalid_token"
    end
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    not_found
  end
end
