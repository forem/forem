class Internal::FeedbackMessagesController < Internal::ApplicationController
  layout "internal"

  def index
    @feedback_type = params[:state] || "abuse-reports"
    @feedback_messages = FeedbackMessage.
      where(feedback_type: @feedback_type).
      order("created_at DESC").
      page(params[:page] || 1).per(25)
  end

  def update
    @feedback_message = FeedbackMessage.find(session[:id])
    @feedback_message.status = feedback_message_params[:status]
    @feedback_message.reviewer_id = feedback_message_params[:reviewer_id]
    note = @feedback_message.find_or_create_note(@feedback_message.feedback_type)
    note.content = feedback_message_params[:note][:content]
    if @feedback_message.save! && note.save!
      @feedback_message.touch(:last_reviewed_at)
      flash[:success] = "Report ##{@feedback_message.id} saved. Remember to send emails!"
      redirect_to URI.parse("/internal/reports?state=#{@feedback_message.feedback_type}")
    else
      @feedback_messages = FeedbackMessage.where(feedback_type: @feedback_type)
      flash[:error] = @feedback_message.errors.full_messages
      render "index.html.erb", state: @feedback_message.feedback_type
    end
  end

  private

  def feedback_message_params
    params[:feedback_message].permit(
      :status, :reviewer_id,
      note: %i[content reason]
    )
  end
end
