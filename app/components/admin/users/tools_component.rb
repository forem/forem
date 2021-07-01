module Admin
  module Users
    class ToolsComponent < ViewComponent::Base
      include ActiveModel::Validations

      validates :emails, presence: true

      # REMINDER: should these hashes be simply sub components?
      # @param emails [Hash] {count:, verified:}
      def initialize(emails: {})
        @emails = emails
      end

      private

      def num_emails; end
    end
  end
end
