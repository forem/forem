class PollTextResponsesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_poll

  def create
    session_start = params[:poll_text_response][:session_start]&.to_i || 0

    # Check if this poll belongs to a survey and if resubmission is allowed
    if @poll.survey.present? && !@poll.survey.can_user_submit?(current_user)
      render json: { success: true, message: "Text response submitted successfully" }
      return
    end

    # For survey polls, find or initialize within the same session so users can update responses via Previous/Next
    # For regular polls, build a new response to preserve existing non-survey behavior
    @text_response = if @poll.survey.present?
                       @poll.poll_text_responses.find_or_initialize_by(
                         user: current_user,
                         session_start: session_start,
                       )
                     else
                       @poll.poll_text_responses.build(
                         user: current_user,
                         session_start: session_start,
                       )
                     end
    @text_response.text_content = params[:poll_text_response][:text_content]

    if @text_response.save
      # Check if this response completes a survey
      SurveyCompletionService.check_and_mark_completion(user: current_user, poll: @poll)
    else
      Rails.error.report(StandardError.new("PollTextResponse save failed"), context: {
                           user_id: current_user&.id,
                           poll_id: @poll&.id,
                           errors: @text_response.errors.full_messages,
                           action: "poll_text_response_create",
                         })
    end

    render json: { success: true, message: "Text response submitted successfully" }
  rescue StandardError => e
    Rails.error.report(e, context: {
                         user_id: current_user&.id,
                         poll_id: params[:poll_id],
                         action: "poll_text_response_create",
                       })
    render json: { success: true, message: "Text response submitted successfully" }
  end

  private

  def set_poll
    @poll = Poll.find(params[:poll_id])
  end
end
