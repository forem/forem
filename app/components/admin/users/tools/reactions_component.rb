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
          user.related_negative_reactions
            .includes(:reactable)
            .order(created_at: :desc)
            .limit(15)
        end
      end
    end
  end
end
