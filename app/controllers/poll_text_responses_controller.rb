class PollTextResponsesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_poll

  def create
    @text_response = @poll.poll_text_responses.build(
      user: current_user,
      text_content: params[:poll_text_response][:text_content],
    )

    if @text_response.save
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
