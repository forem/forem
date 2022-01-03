module Admin
  module Users
    module Tools
      class NotesController < Admin::ApplicationController
        layout false

        def show
          user = ::User.find(params[:user_id])

          render_component(NotesComponent, user: user)
        end

        def create
          user = ::User.find(params[:user_id])

          note = user.notes.build(note_params.merge(author: current_user, reason: :misc_note))
          respond_to do |format|
            format.js do
              if note.save
                render json: { result: "Note created!" }, content_type: "application/json", status: :created
              else
                render json: { error: note.errors_as_sentence },
                       content_type: "application/json",
                       status: :unprocessable_entity
              end
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
