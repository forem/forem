class FeedbackMessagesController < ApplicationController
  # No authorization required for entirely public controller
  skip_before_action :verify_authenticity_token

  def create
    flash.clear
    rate_limit!(:feedback_message_creation)

    params = feedback_message_params.merge(reporter_id: current_user&.id)
    @feedback_message = FeedbackMessage.new(params)

    recaptcha_enabled = ReCaptcha::CheckEnabled.call(current_user)
    if (!recaptcha_enabled || recaptcha_verified? || connect_feedback?) && @feedback_message.save
      Slack::Messengers::Feedback.call(
        user: current_user,
        type: feedback_message_params[:feedback_type],
        category: feedback_message_params[:category],
        reported_url: feedback_message_params[:reported_url],
        message: feedback_message_params[:message],
      )
      rate_limiter.track_limit_by_action(:feedback_message_creation)

      if user_signed_in?
        Rails.cache.fetch("user-#{current_user.id}-feedback-response-sent-at", expires_in: 24.hours) do
          NotifyMailer.with(email_to: current_user.email).feedback_response_email.deliver_later
          Time.current
        end
      end

      respond_to do |format|
        format.html { redirect_to feedback_messages_path }
        format.json { render json: { success: true, message: "Your report is submitted" } }
      end
    else
      @previous_message = feedback_message_params[:message]
      flash[:notice] = "Make sure the forms are filled 🤖"

      respond_to do |format|
        format.html { render "pages/report_abuse" }
        format.json do
          render json: {
            success: false,
            message: @feedback_message.errors_as_sentence,
            status: :bad_request
          }
        end
      end
    end
  end

  private

  def recaptcha_verified?
    recaptcha_params = { secret_key: SiteConfig.recaptcha_secret_key }
    params["g-recaptcha-response"] && verify_recaptcha(recaptcha_params)
  end

  def connect_feedback?
    feedback_message_params[:feedback_type] == "connect"
  end

  def feedback_message_params
    allowed_params = %i[message feedback_type category reported_url offender_id]
    params.require(:feedback_message).permit(allowed_params)
  end
end
