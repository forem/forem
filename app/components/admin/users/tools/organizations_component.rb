module Admin
  module Users
    module Tools
      class OrganizationsComponent < ViewComponent::Base
        MEMBERSHIPS_FOR_SELECT = [
          ["Member", :member],
          ["Admin", :admin],
        ].freeze

        def initialize(user:)
          @user = user
          @memberships_for_select = MEMBERSHIPS_FOR_SELECT
        end
      end
    end
  end
end
