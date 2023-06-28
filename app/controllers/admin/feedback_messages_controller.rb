module Admin
  class FeedbackMessagesController < Admin::ApplicationController
    layout "admin"

    def index
      @q = FeedbackMessage.includes(:reporter, :offender, :affected)
        .order(created_at: :desc)
        .ransack(params[:q])
      @feedback_messages = @q.result.page(params[:page] || 1).per(5)

      @feedback_type = params[:state] || "abuse-reports"
      @status = params[:status] || "Open"

      @email_messages = EmailMessage.find_for_reports(@feedback_messages)

      @vomits = get_vomits
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
      @email_messages = EmailMessage.find_for_reports(@feedback_message.id)
    end

    def send_email
      if NotifyMailer.with(params).feedback_message_resolution_email.deliver_now
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
        params["author_name"] = note.author.name
        params["feedback_message_status"] = note.noteable.status
        params["feedback_type"] = note.noteable.feedback_type

        send_slack_message(params)

        render json: {
          outcome: "Success",
          content: params["content"],
          author_name: note.author.name
        }
      else
        render json: { outcome: note.errors.full_messages }
      end
    end

    private

    def get_vomits
      status, limit = case params[:status]
                      when "Open", ->(s) { s.blank? }
                        ["valid", nil]
                      when "Resolved"
                        ["confirmed", 10]
                      else
                        ["invalid", 10]
                      end
      q = Reaction.includes(:user, :reactable)
        .where(category: "vomit", status: status)
        .select(:id, :user_id, :reactable_type, :reactable_id)
        .order(updated_at: :desc)
        .limit(limit)
      # don't show reactions where the reactable was not found
      q.select(&:reactable)
    end

    def send_slack_message(params)
      Slack::Messengers::Note.call(
        author_name: params[:author_name],
        status: params[:feedback_message_status],
        type: params[:feedback_type],
        report_id: params[:noteable_id],
        message: params[:content],
      )
    end

    def generate_message(params)
      <<~HEREDOC
        *New note from #{params['author_name']}:*
        *Report status: #{params['feedback_message_status']}*
        Report page: admin_report_url(params['noteable_id'])
        --------
        Message: #{params['content']}
      HEREDOC
    end

    def feedback_message_params
      params[:feedback_message].permit(
        :id, :status, :reviewer_id,
        note: %i[content reason noteable_id noteable_type author_id]
      )
    end
  end
end
