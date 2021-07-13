module Admin
  module Users
    class ToolsComponent < ViewComponent::Base
      include ActiveModel::Validations

      validates :emails, :notes, presence: true

      # REMINDER: should these hashes be simply sub components?
      # @param emails [Hash] {count:, verified:}
      # @param notes [Hash] {count:}
      def initialize(emails: {}, notes: {})
        @emails = emails
        @notes = notes
      end

      private

      def num_emails; end
    end
  end
end
