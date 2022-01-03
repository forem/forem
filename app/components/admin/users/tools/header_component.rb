module Admin
  module Users
    module Tools
      class HeaderComponent < ViewComponent::Base
        def initialize(title:, user:)
          @title = title
          @user = user
        end
      end
    end
  end
end
