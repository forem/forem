class EmailSubscriptionsController < ApplicationController
  # No need to authorize this because its implicit when unsubbing
  def unsubscribe
    verified_params = Rails.application.message_verifier(:unsubscribe).verify(params[:ut])

    if verified_params[:expires_at] > Time.current
      user = User.find(verified_params[:user_id])
      user.update(verified_params[:email_type] => false)
      @email_type = preferred_email_name(verified_params[:email_type])
    else
      render "invalid_token"
    end
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    not_found
  end

  def preferred_email_name(given_email_type)
    emails_type = {
      email_digest_periodic: "DEV digest emails",
      email_comment_notifications: "comment notifications",
      email_follower_notifications: "follower notifications",
      email_mention_notifications: "mention notifications",
      email_connect_messages: "connect messages",
      email_unread_notifications: "unread notifications"
    }
    emails_type[given_email_type]
  end
end
