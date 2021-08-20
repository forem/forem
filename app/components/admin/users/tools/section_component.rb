module Admin
  module Users
    module Tools
      class SectionComponent < ViewComponent::Base
        renders_one :title

        def initialize(user:)
          @user = user
        end
      end
    end
  end
end
