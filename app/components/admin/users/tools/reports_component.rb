module Admin
  module Users
    module Tools
      class ReportsComponent < ViewComponent::Base
        def initialize(user:)
          @user = user
          @reports = user.reports.order(created_at: :desc).limit(15)
        end
      end
    end
  end
end
