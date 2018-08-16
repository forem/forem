class Internal::FeedbackMessagesController < Internal::ApplicationController
  layout "internal"

  def index
    @feedback_type = params[:state] || "abuse-reports"
    @status = params[:status] || "Open"
    @feedback_messages = FeedbackMessage.
      where(feedback_type: @feedback_type, status: @status).
      order("created_at DESC").
      page(params[:page] || 1).per(25)
  end

  def update
    @feedback_message = FeedbackMessage.find(params[:id])
    note = @feedback_message.notes.new(feedback_message_params[:note])
    update_feedback_message_and_note(note)
    if @feedback_message.save && note.save
      @feedback_message.touch(:last_reviewed_at)
      flash[:success] = "Report ##{@feedback_message.id} saved."
      redirect_to "/internal/feedback_messages/#{@feedback_message.id}"
    else
      @feedback_type = @feedback_message.feedback_type
      @feedback_messages = FeedbackMessage.
        where(feedback_type: @feedback_type).
        order("created_at DESC").
        page(params[:page] || 1).per(25)
      flash[:danger] = "Something went wrong. Did you leave a blank note?"
      render "index.html.erb", state: @feedback_type
    end
  end

  def show
    @feedback_message = FeedbackMessage.find_by(id: params[:id])
  end

  def update_feedback_message_and_note(note)
    @feedback_message.status = feedback_message_params[:status]
    note.content = feedback_message_params[:note][:content]
    note.author_id = current_user.id
  end

  def send_email
    NotifyMailer.feedback_message_resolution_email(params).deliver
  end

  private

  def feedback_message_params
    params[:feedback_message].permit(
      :status, :reviewer_id,
      note: %i[content reason noteable_id noteable_type author_id]
    )
  end
end
