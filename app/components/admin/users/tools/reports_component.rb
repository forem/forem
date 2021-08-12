module Admin
  module Users
    module Tools
      class ReportsComponent < ViewComponent::Base
        def initialize(user:)
          @user = user
          @reports = FeedbackMessage.all_user_reports(user).order(created_at: :desc).limit(15)
        end
      end
    end
  end
end
