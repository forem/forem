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
          @memberships = @user.organization_memberships
            .joins(:organization)
            .order("organizations.name" => :asc)
            .includes(:organization)
        end
      end
    end
  end
end
