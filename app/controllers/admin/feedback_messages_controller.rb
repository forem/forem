module Admin
  class FeedbackMessagesController < Admin::ApplicationController
    layout "admin"

    def index
      reconcile_ransack_params
      @q = FeedbackMessage.includes(:reporter, :offender, :affected)
        .order(created_at: :desc)
        .ransack(params[:q])
      @feedback_messages = @q.result.page(params[:page] || 1).per(10)
      @feedback_messages = if params[:status] == "Resolved"
                             @feedback_messages.where(status: "Resolved")
                           elsif params[:status] == "Invalid"
                             @feedback_messages = @feedback_messages.where(status: "Invalid")
                           else
                             @feedback_messages = @feedback_messages.where(status: "Open")
                           end

      @feedback_type = params[:state] || "abuse-reports"
      @status = params[:status].presence || "Open"

      @email_messages = EmailMessage.find_for_reports(@feedback_messages)
      @notes = Note.find_for_reports(@feedback_messages)

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
      @notes = Note.find_for_reports(@feedback_message)
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
        .live_reactable
        .select(:id, :user_id, :reactable_type, :reactable_id)
        .where("reactions.created_at > ?", 2.week.ago)
        .order(Arel.sql("
          CASE reactable_type
            WHEN 'User' THEN 0
            WHEN 'Comment' THEN 1
            WHEN 'Article' THEN 2
            ELSE 3
          END,
          reactions.reactable_id ASC"))
        .limit(limit)
      # don't show reactions where the reactable was not found
      q.select(&:reactable)
      # Map over reactions and do not include reactions where the reactable's score is less than 150
      q.select { |reaction| reaction.reactable.score > -150 }
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

    def reconcile_ransack_params
      params[:q] ||= {}
      if params[:status].blank? && params.dig(:q, :status_eq).present?
        params[:status] = params[:q][:status_eq]
      end
      if params[:category].blank? && params.dig(:q, :category_eq).present? # rubocop:disable Style/GuardClause
        params[:category] = params[:q][:category_eq]
      end
    end
  end
end
