module Admin
  module Users
    class ToolsComponent < ViewComponent::Base
      renders_one :emails

      def initialize(user:, num_emails:, verified:)
        @user = user

        # emails
        @num_emails = num_emails
        @verified = verified
      end

      private

      def num_emails; end
    end
  end
end
