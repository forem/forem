class PollTextResponsesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_poll

  def create
    session_start = params[:poll_text_response][:session_start]&.to_i || 0

    # Check if this poll belongs to a survey and if resubmission is allowed
    if @poll.survey.present? && !@poll.survey.can_user_submit?(current_user)
      render json: { error: "Survey does not allow resubmission" }, status: :forbidden
      return
    end

    # Create a new text response with the session_start
    @text_response = @poll.poll_text_responses.build(
      user: current_user,
      text_content: params[:poll_text_response][:text_content],
      session_start: session_start,
    )

    if @text_response.save
      # Check if this response completes a survey
      SurveyCompletionService.check_and_mark_completion(user: current_user, poll: @poll)

      render json: { success: true, message: "Text response submitted successfully" }
    else
      render json: { success: false, errors: @text_response.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_poll
    @poll = Poll.find(params[:poll_id])
  end
end
