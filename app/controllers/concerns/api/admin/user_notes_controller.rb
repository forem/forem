module Api
  module Admin
    module UserNotesController
      extend ActiveSupport::Concern

      DEFAULT_REASON = "misc_note".freeze

      def index
        target = User.find(params[:user_id])
        @notes = target.notes.order(created_at: :desc)
      end

      def create
        target = User.find(params[:user_id])
        content = params.require(:content)
        reason = params[:reason].presence || DEFAULT_REASON

        @note = Note.create!(
          noteable: target, author: current_user, content: content, reason: reason,
        )
        audit!(slug: "add_user_note",
               data: { "target_user_id" => target.id, "note_id" => @note.id, "reason" => reason })
        render :create, status: :created
      end
    end
  end
end
