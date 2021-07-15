module Admin
  module Users
    class ToolsComponent < ViewComponent::Base
      include ActiveModel::Validations

      validates :emails, :notes, presence: true

      # REMINDER: should the hashes be simply sub components?
      # @param user_id [Integer]
      # @param emails [Hash] {count:, verified:}
      # @param notes [Hash] {count:}
      # @param credits [Hash] {count:}
      def initialize(user_id, emails: {}, notes: {}, credits: {})
        @user_id = user_id
        @emails = emails
        @notes = notes
        @credits = credits
      end

      private

      def num_emails; end
    end
  end
end
