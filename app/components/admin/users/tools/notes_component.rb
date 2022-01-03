module Admin
  module Users
    module Tools
      class NotesComponent < ViewComponent::Base
        def initialize(user:)
          @user = user
          @notes = user.notes.includes(:author).order(created_at: :desc).limit(10)
        end
      end
    end
  end
end
