class Internal::FeedbackMessagesController < Internal::ApplicationController
  layout "internal"

  def index
    @feedback_type = params[:state] || "abuse-reports"
    @status = params[:status] || "Open"
    @feedback_messages = FeedbackMessage.
      where(feedback_type: @feedback_type, status: @status).
      includes(:reporter, :notes).
      order("created_at DESC").
      page(params[:page] || 1).per(5)
  end

  def save_status
    feedback_message = FeedbackMessage.find(params[:id])
    if feedback_message.update(status: params[:status])
      render json: { outcome: "Success" }
    else
      render json: { outcome: feedback_message.errors.full_messages }
    end
  end

  def show
    @feedback_message = FeedbackMessage.find_by(id: params[:id])
  end

  def send_email
    if NotifyMailer.feedback_message_resolution_email(params).deliver
      render json: { outcome: "Success" }
    else
      render json: { outcome: "Failure" }
    end
  end

  def create_note
    note = Note.new(
      noteable_id: params["noteable_id"],
      noteable_type: params["noteable_type"],
      author_id: params["author_id"],
      content: params["content"],
      reason: params["reason"],
    )
    if note.save
      render json: {
        outcome: "Success",
        content: params["content"],
        author_name: note.author.name,
      }
    else
      render json: { outcome: note.errors.full_messages }
    end
  end

  private

  def feedback_message_params
    params[:feedback_message].permit(
      :id, :status, :reviewer_id,
      note: %i[content reason noteable_id noteable_type author_id]
    )
  end
end
