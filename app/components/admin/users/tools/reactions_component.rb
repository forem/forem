module Admin
  module Users
    module Tools
      class ReactionsComponent < ViewComponent::Base
        def initialize(user:)
          @user = user
          @reactions = reactions
        end

        private

        attr_reader :user

        def reactions
          Reaction.related_negative_reactions_for_user(user)
            .includes(:reactable)
            .order(created_at: :desc)
            .limit(15)
        end
      end
    end
  end
end
