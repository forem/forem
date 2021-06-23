module Admin
  module Users
    module Tools
      class EmailComponent < ViewComponent::Base
        delegate :send_email_admin_user_path, to: :helpers

        def initialize(user:, verification_date:)
          @user = user
          @verification_date = verification_date
          @verified = @verification_date.present?
        end
      end
    end
  end
end
