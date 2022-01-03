module Admin
  module Users
    module Tools
      class CreditsComponent < ViewComponent::Base
        delegate :orgs_with_credits, to: :helpers

        def initialize(user:)
          @user = user
          @user_unspent_credits_count = user.unspent_credits_count
          @organizations = user.organizations.order(:name)
        end
      end
    end
  end
end
