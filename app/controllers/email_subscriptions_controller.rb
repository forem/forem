class EmailSubscriptionsController < ApplicationController
  def unsubscribe
    verified_params = Rails.application.message_verifier(:unsubscribe).verify(params[:ut])

    if verified_params[:expires_at] > Time.now
      user = User.find(verified_params[:user_id])
      user.update(verified_params[:email_type] => false)
    else
      not_found
    end
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    not_found
  end
end
