module Admin
  module Users
    module Tools
      class NotesController < Admin::ApplicationController
        layout false

        def show
          user = ::User.find(params[:user_id])

          render NotesComponent.new(user: user), content_type: "text/html"
        end

        def create
          user = ::User.find(params[:user_id])

          note = user.notes.build(note_params.merge(author: current_user, reason: :misc_note))
          respond_to do |format|
            if note.save
              format.js { head :no_content }
            else
              format.js { render json: { error: note.errors_as_sentence }, status: :unprocessable_entity }
            end
          end
        end

        private

        def authorization_resource
          User
        end

        def note_params
          params.require(:note).permit(:content)
        end
      end
    end
  end
end
