module Admin
  module Users
    module Tools
      class EmailsComponent < ViewComponent::Base
        delegate :send_email_admin_user_path, to: :helpers

        def initialize(user:)
          @user = user
          @verification_date = EmailAuthorization.last_verification_date(user)
          @verified = @verification_date.present?
          @messages = user.email_messages.order(sent_at: :desc).limit(50)
        end
      end
    end
  end
end
