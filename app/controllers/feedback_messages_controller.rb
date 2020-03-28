class FeedbackMessagesController < ApplicationController
  # No authorization required for entirely public controller
  skip_before_action :verify_authenticity_token

  def create
    flash.clear

    params = feedback_message_params.merge(reporter_id: current_user&.id)
    @feedback_message = FeedbackMessage.new(params)

    if recaptcha_verified? && @feedback_message.save
      Slack::Messengers::Feedback.call(
        user: current_user,
        type: feedback_message_params[:feedback_type],
        category: feedback_message_params[:category],
        reported_url: feedback_message_params[:reported_url],
        message: feedback_message_params[:message],
      )

      redirect_to feedback_messages_path
    else
      @previous_message = feedback_message_params[:message]

      flash[:notice] = "Make sure the forms are filled 🤖"
      render "pages/report-abuse"
    end
  end

  private

  def recaptcha_verified?
    recaptcha_params = { secret_key: ApplicationConfig["RECAPTCHA_SECRET"] }
    params["g-recaptcha-response"] && verify_recaptcha(recaptcha_params)
  end

  def feedback_message_params
    allowed_params = %i[message feedback_type category reported_url]
    params.require(:feedback_message).permit(allowed_params)
  end
end
