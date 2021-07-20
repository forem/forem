module Admin
  module Users
    class ToolsComponent < ViewComponent::Base
      include ActiveModel::Validations

      DATA = Struct.new(:total, :verified, keyword_init: true)

      validates :emails, :notes, presence: true

      def initialize(user)
        @user = user
        @emails = emails
        @notes = notes
        @credits = credits
      end

      private

      attr_reader :user

      def emails
        DATA.new(
          total: [user.email_messages.count, 50].min, # we only display 50 emails at most
          verified: user.last_verification_date.present?,
        )
      end

      def notes
        DATA.new(
          total: [user.notes.count, 10].min, # we only display 10 notes at most
        )
      end

      def credits
        DATA.new(
          total: user.unspent_credits_count,
        )
      end
    end
  end
end
