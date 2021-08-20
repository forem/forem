module Admin
  module Users
    module Tools
      class HeaderComponent < ViewComponent::Base
        def initialize(user:)
          @user = user
        end
      end
    end
  end
end
