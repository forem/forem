module Admin
  module Users
    module Tools
      class EmailComponent < ViewComponent::Base
        delegate :send_email_admin_user_path, to: :helpers

        def initialize(user:, verification_date:)
          @user = user
          @verification_date = verification_date
          @verified = verification_date.present?
          @messages = user.email_messages.order(sent_at: :desc).limit(50)
        end
      end
    end
  end
end
